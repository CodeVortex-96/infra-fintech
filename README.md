

## How It Works

Every piece of this infrastructure has a reason to exist. Here's how they connect end to end.

**A developer pushes code to `main`.** GitHub Actions fires immediately. Before anything else, Terraform validates the infrastructure configuration — if the IaC has a syntax error or an invalid resource reference, the pipeline stops here. Nothing broken reaches the cluster.

**The pipeline builds the Docker image** tagged with the exact commit SHA and patches the tag in `k8s/deployment.yaml`. It commits that change back to the repository with a bot identity and pushes. The repository is now the updated source of truth.

**ArgoCD detects the manifest change** within seconds. It compares the desired state in Git against the actual state in the cluster, finds the new image tag, and syncs. If someone manually changed something in the cluster that doesn't match Git — ArgoCD corrects it automatically. The cluster always reflects what's in the repository, nothing else.

**Kubernetes rolls out the new pods** using RollingUpdate with `maxUnavailable: 0`. A new pod starts, passes the readiness probe (which tests a real database connection), and only then does the old pod terminate. Zero downtime. If the new pod fails the readiness probe, the rollout stops and the old version keeps serving traffic.

**Traffic enters through the Ingress Controller**, which terminates TLS and forwards HTTP requests to the Flask API pods. The API sits in a private subnet — it's never directly reachable. Only the Ingress has a public entry point.

**The Flask API processes the request** through three explicit layers: the route receives the HTTP request, the service validates the business rules, the repository executes the database operation with a connection from the pool. If anything fails at the database level, the transaction rolls back and the connection returns to the pool — no leak, no corruption.

**Prometheus scrapes `/metrics` every 15 seconds**, collecting request count, latency histograms, and process metrics. Grafana reads from Prometheus and displays real-time availability, throughput (TPS), P95/P99 latency, and CPU saturation across pods. If something breaks, the dashboard shows it before users notice.

**The database never touches the internet.** PostgreSQL is exposed only as a ClusterIP service — accessible exclusively from within the cluster, only by pods that know the service name. Credentials are injected via Kubernetes Secrets, never hardcoded. The Terraform layer manages an AWS Secrets Manager secret for API-level credentials, separate from the cluster secrets lifecycle.

See README for details.
