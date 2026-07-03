infra-fintech

Infrastructure reference for a financial transaction API, built with production-grade tooling from the ground up. This project was designed to demonstrate how a real fintech platform is structured — not just the happy path, but the security, resilience, observability, and deployment strategy that actually matters when money is involved.


What this is

A complete infrastructure stack for a financial API, covering every layer that a real platform needs:


A containerized Python/Flask API following Clean Architecture principles
PostgreSQL with persistent storage, managed via Kubernetes
Full observability with Prometheus scraping and a Grafana dashboard built for financial KPIs
GitOps deployment pipeline using ArgoCD — every change to the repo triggers a real sync
Modular Terraform provisioning targeting AWS EKS, with state locking via S3 and DynamoDB
TLS termination, rate limiting, and network segmentation from day one


No credentials in code. No shortcuts on security. No "we'll fix this later" comments left open.


Architecture

GitHub Repository (GitOps source of truth)
         |
         v
Terraform (AWS Infrastructure)
  - VPC with public/private subnet segmentation
  - NAT Gateway for private egress
  - EKS cluster with private API endpoint
  - AWS Secrets Manager for credential management
         |
         v
Kubernetes Cluster
  - Ingress Controller (NGINX/Traefik) with TLS
  - ArgoCD watching the repo and syncing automatically
         |
         v
Flask API Pods (2 replicas, RollingUpdate, zero downtime)
  - Service layer / Repository layer / Routes (Clean Architecture)
  - Prometheus metrics exposed at /metrics
         |
    _____|_____
   |           |
   v           v
PostgreSQL   Prometheus
(PVC disk)       |
                 v
           Grafana Dashboard
           (uptime, TPS, P95/P99 latency, CPU saturation)

The API sits in a private subnet. The only entry point is the Ingress Controller, which terminates TLS and forwards traffic. PostgreSQL is never exposed — it communicates only within the cluster via ClusterIP. The ArgoCD panel is protected by Traefik middleware with rate limiting and security headers.


Project Structure

infra-fintech/
├── app/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── src/
│       ├── main.py
│       ├── db.py
│       ├── metrics.py
│       ├── repositories/
│       │   └── transacao_repo.py
│       ├── routes/
│       │   └── transacao_routes.py
│       └── services/
│           └── transacao_service.py
├── argocd/
│   ├── argocd-ingress.yaml
│   ├── argocd-middlewares.yaml
│   ├── argocd-network-policy.yaml
│   ├── fintech-app.yaml
│   └── monitoring-stack.yaml
├── k8s/
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── postgres.yaml
│   ├── secret.yaml
│   ├── service.yaml
│   └── monitoring/
│       ├── dashboard-fintech.yaml
│       ├── prometheus-deployment.yaml
│       └── service-monitor.yaml
├── terraform/
│   ├── main.tf
│   ├── backend.tf
│   └── modules/
│       ├── rede/
│       ├── security/
│       ├── eks/
│       └── secrets/
├── deploy.sh
└── .github/workflows/ci-cd.yml


Application Layer

Dockerfile — Multi-Stage Build

The image is built in two stages. The first stage (builder) installs gcc, musl-dev, and libffi — everything needed to compile Python packages with C extensions. The second stage (runner) copies only the compiled output, discards the build toolchain, and runs the application as a non-root user (arquiteto, group fintech).

The result is a minimal Alpine image with no compiler, no build tools, and no root privileges. Attack surface reduced by design, not by accident.

Application Architecture — Clean Separation of Concerns

The codebase follows a strict three-layer structure:

routes/transacao_routes.py — The HTTP boundary. Receives JSON, calls the service, returns formatted responses. No business logic here. HTTP concerns stay in HTTP layer.

services/transacao_service.py — Business rules live here, and only here. Validates transaction type (credito/debito), enforces numeric type checking, rejects zero and negative values. If the data doesn't make sense financially, it never reaches the database.

repositories/transacao_repo.py — Database access, nothing else. Handles the connection pool, executes parameterized queries (no SQL injection surface), commits on success, rolls back on failure, always returns the connection to the pool in the finally block. No connection leak possible.

db.py — Initializes the PostgreSQL connection pool at startup. If the database isn't reachable, the application exits immediately rather than serving requests in a broken state. Fail fast, fail loud.

metrics.py — Integrates prometheus-flask-exporter with the application factory pattern. Exposes request count by path, method, and status code. This feeds the Grafana dashboard with real-time data.

main.py — Application factory (create_app()). Wires up metrics, database, routes, and health check in explicit order. The health check at / actually validates database connectivity — it doesn't just return 200, it tries to acquire a connection from the pool. Kubernetes uses this to decide whether to send traffic to the pod.


Kubernetes Layer

deployment.yaml

Two replicas with RollingUpdate strategy: maxSurge: 1, maxUnavailable: 0. This means a new pod must be fully ready before the old one is terminated. Zero downtime on deploy, guaranteed by configuration rather than hope.

Liveness and readiness probes hit the / health check. If the database goes down, readiness fails first — traffic stops reaching that pod. If the pod enters a broken state that liveness can't recover from, Kubernetes kills and restarts it automatically.

CPU and memory limits are set explicitly. A pod that misbehaves cannot take down the entire node.

Database credentials are injected via secretKeyRef, never hardcoded or passed as plain environment variables.

postgres.yaml

Single replica — correct for a relational database where write conflicts between replicas would require distributed consensus, which is out of scope here. Data persists across pod restarts via a PersistentVolumeClaim. Exposed internally only via ClusterIP — no path from outside the cluster to the database exists.

ingress.yaml

TLS termination at the ingress layer. All HTTP traffic is redirected to HTTPS automatically. The TLS secret is referenced by name — certificates are not stored in the repository.

secret.yaml

Credentials stored as base64-encoded Kubernetes Secrets, referenced by the deployment and the postgres pod. The actual values are placeholders — in a real deployment, these would be injected via an external secrets operator or populated from AWS Secrets Manager.

Monitoring Stack

service-monitor.yaml — Tells Prometheus Operator exactly which pods to scrape and how. Selector matches the team: fintech label on the service. metricRelabelings filters the collected metrics to only what's relevant — request metrics, CPU, and memory. Keeps the Prometheus TSDB clean.

prometheus-deployment.yaml — Two replicas for high availability. Thirty days of metric retention, which covers standard financial compliance requirements for operational data. Twenty gigabytes of persistent storage so no metrics are lost on restart.

dashboard-fintech.yaml — Grafana ConfigMap with a pre-built dashboard covering the four signals that matter in a financial system: availability (uptime calculated from 5xx rate), throughput (transactions per second), latency (P95 and P99 percentiles), and saturation (CPU usage per pod).


ArgoCD — GitOps

fintech-app.yaml

ArgoCD Application manifest pointing to the k8s/ directory of this repository. The sync policy is fully automated: selfHeal: true means ArgoCD corrects any manual change made directly to the cluster (drift correction). prune: true means resources deleted from Git are deleted from the cluster. allowEmpty: false prevents an accidental empty commit from deleting everything.

Retry strategy with exponential backoff handles transient network failures during sync without operator intervention.

argocd-middlewares.yaml

Traefik middleware protecting the ArgoCD UI. Rate limiting set to 50 requests/second average with burst of 20 — prevents brute force against the ArgoCD login. Security headers (X-XSS-Protection, Content-Type-Options, Strict-Transport-Security) applied at the proxy layer, not the application layer.

argocd-network-policy.yaml

Kubernetes NetworkPolicy restricting ingress to the ArgoCD server pod. Only traffic originating from the kube-system namespace (where the Ingress Controller runs) is allowed. Direct pod-to-pod access from other namespaces is blocked.


Terraform — AWS Infrastructure

The Terraform code is organized as a module composition. main.tf is the orchestrator — it calls each module with explicit inputs and wires outputs between them. No monolithic resource files.

modules/rede

VPC with CIDR 10.0.0.0/16. Public subnet for the load balancer tier. Private subnet for the application and database tier. Internet Gateway for public egress. NAT Gateway in the public subnet so private resources can reach the internet for updates without being reachable from it.

Route tables configured explicitly: public subnet routes to the Internet Gateway, private subnet routes to the NAT Gateway. Variables include CIDR validation — if an invalid IP block is passed, Terraform rejects the plan before touching AWS.

modules/security

Two Security Groups using the modern aws_vpc_security_group_ingress_rule resource (not inline rules — avoids state drift on rule updates). The load balancer SG accepts HTTP on port 80 from anywhere. The API SG accepts traffic on port 8080 only from the load balancer SG — not from the internet, not from other security groups. Egress allowed for both to reach NAT Gateway for updates.

modules/eks

EKS cluster with endpoint_public_access: false. The Kubernetes API is not reachable from the internet. Control plane logging enabled for all log types: API, audit, authenticator, controller manager, scheduler. These logs are what you need for PCI-DSS audit trails.

modules/secrets

AWS Secrets Manager secret for API credentials. lifecycle { ignore_changes = [secret_string] } prevents Terraform from overwriting values set manually or by a rotation process. The infrastructure manages the secret container — the secret value lifecycle is managed separately.

backend.tf

Remote state in S3 with server-side encryption. State locking via DynamoDB prevents concurrent terraform apply runs from corrupting the state file. Standard practice for any team environment.


CI/CD Pipeline

Two-stage pipeline on push to main, ignoring commits to k8s/deployment.yaml (those are made by the pipeline itself — prevents infinite loop).

Stage 1 — terraform-check: Initializes Terraform without backend (-backend=false) and validates the configuration. Catches syntax errors and invalid resource references before anything touches production.

Stage 2 — gitops-sync: Builds the Docker image tagged with the commit SHA, patches the image tag in k8s/deployment.yaml, commits the change back to the repository with a bot identity, and pushes. ArgoCD detects the manifest change and syncs the cluster automatically. The cluster state always reflects what's in Git.


Local Development

bash# Start cluster
./deploy.sh

# Apply manifests manually
kubectl apply -f k8s/

# Watch deployment
kubectl rollout status deployment/fintech-api-deployment

# Test the API
curl -X POST http://fintech.local/transacao \
  -H "Content-Type: application/json" \
  -d '{"tipo": "credito", "valor": 150.00}'

# Check metrics
curl http://fintech.local/metrics


Tech Stack

LayerTechnologyApplicationPython 3.11, Flask, psycopg2ContainerizationDocker (multi-stage, Alpine)OrchestrationKubernetes (k3d locally, EKS on AWS)GitOpsArgoCDIngressNGINX / TraefikDatabasePostgreSQL 15ObservabilityPrometheus, GrafanaInfrastructureTerraform (modular)CloudAWS (VPC, EKS, Secrets Manager, S3, DynamoDB)CI/CDGitHub Actions


Design Decisions

Why Clean Architecture in the application layer? Business rules in services/, database access in repositories/, HTTP in routes/. Each layer has one reason to change. Adding a new endpoint doesn't touch the database code. Swapping PostgreSQL for another database doesn't touch the business logic. This scales with a team.

Why GitOps instead of direct kubectl in CI? The cluster state is always derived from the repository. Rollback is a git revert. Audit trail is the commit history. No manual imperative commands that nobody documented.

Why modular Terraform? main.tf reads like an architecture diagram. Each module has a single responsibility and explicit inputs and outputs. Reusable across environments — pass env = "staging" and get a staging environment with the same structure.

Why private EKS endpoint? The Kubernetes API should not be on the internet. Access to the control plane goes through a bastion or VPN, not a public IP.



This project was built as an infrastructure reference, not a production deployment. AWS credentials, real certificates, and actual secret values are not included. The Terraform state backend and EKS cluster require a real AWS account to provision.
