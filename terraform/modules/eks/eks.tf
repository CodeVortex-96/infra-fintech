variable "env" { type = string }
variable "eks_role_arn" { type = string }
variable "subnet_ids" { type = list(string) }
variable "eks_sg_id" { type = string }
variable "kubernetes_version" { 
  type    = string 
  default = "1.30" # Sempre defina a versão explicitamente
}

resource "aws_eks_cluster" "fintech_eks" {
  name     = "fintech-cluster-${var.env}"
  role_arn = var.eks_role_arn
  version  = var.kubernetes_version

  # Nível Tech Lead: Configuração de rede e acesso
  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.eks_sg_id]
    endpoint_private_access = true  # A API do cluster não deve ser exposta na internet
    endpoint_public_access  = false 
  }

  # Nível Fintech: Logs de auditoria (Control Plane Logging)
  # Essencial para conformidade (PCI-DSS/SOC2)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name        = "fintech-cluster-${var.env}"
    ManagedBy   = "Terraform"
    Environment = var.env
    Security    = "Critical"
  }
}
