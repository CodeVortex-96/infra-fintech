variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "O CIDR informado não é um formato de bloco IP válido."
  }
}

variable "env" {
  description = "Ambiente (prod, dev, staging)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "dev"], var.env)
    error_message = "O ambiente deve ser 'production', 'staging' ou 'dev'."
  }
}

# Variáveis adicionadas para resolver o erro de Unsupported Argument
variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR da subnet privada"
  type        = string
}

variable "region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}
