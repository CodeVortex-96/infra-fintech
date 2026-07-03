variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  # Aqui entra o nível Tech Lead: Validação
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "O CIDR informado não é um formato de bloco IP válido."
  }
}

variable "env" {
  description = "Ambiente (prod, dev, staging)"
  type        = string
  default     = "production"

  # Validação de lista permitida
  validation {
    condition     = contains(["production", "staging", "dev"], var.env)
    error_message = "O ambiente deve ser 'production', 'staging' ou 'dev'."
  }
}
