# Define que vamos usar o provedor da AWS (padrão de mercado para Fintechs)
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
  region = "us-east-1" # Região padrão de baixa latência e custo
}

# 1. Criação da VPC (O escudo da nossa rede)
resource "aws_vpc" "fintech_vpc" {
  cidr_block           = "10.0.0.0/16" # Espaço para até 65 mil IPs internos
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "fintech-production-vpc"
    Environment = "production"
  }
}
