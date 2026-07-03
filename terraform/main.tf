# Orquestrador Central da Fintech Infrastructure
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Rede (Fundação)
module "rede" {
  source              = "./modules/rede"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.10.0/24"
  env                 = "production"
}

# 2. Segurança (Proteção)
module "security" {
  source = "./modules/security"
  vpc_id = module.rede.vpc_id
}

# 3. Segredos (Gestão de Credenciais)
module "secrets" {
  source = "./modules/secrets"
  env    = "production"
}

# 4. Cluster (Core da Aplicação)
module "eks" {
  source       = "./modules/eks"
  env          = "production"
  eks_role_arn = "arn:aws:iam::123456789012:role/eks-cluster-role"
  
  # Aqui fazemos a "amarracão" de dependência real entre os módulos
  subnet_ids   = [module.rede.private_subnet_id] 
  eks_sg_id    = module.security.api_sg_id
}
