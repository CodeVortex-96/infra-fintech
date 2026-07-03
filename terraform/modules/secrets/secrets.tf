variable "env" {
  description = "Ambiente (prod, staging, dev)"
  type        = string
  validation {
    condition     = contains(["production", "staging", "dev"], var.env)
    error_message = "Ambiente inválido. Use: production, staging ou dev."
  }
}

# 1. Secret Manager (Definição do contêiner do segredo)
resource "aws_secretsmanager_secret" "api_secret" {
  name        = "fintech/api-key/${var.env}"
  description = "Chave de autenticacao da API da Fintech - Gerenciado por Terraform"

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.env
    Security    = "High"
  }
}

# 2. Definição do valor inicial
resource "aws_secretsmanager_secret_version" "api_secret_version" {
  secret_id     = aws_secretsmanager_secret.api_secret.id
  secret_string = jsonencode({
    api_key = "placeholder-value"
  })

  # Sênior Move: Isso evita que o Terraform tente atualizar o secret_string 
  # toda vez que você rodar um plano, mantendo o valor que você setou manualmente no console/CLI
  lifecycle {
    ignore_changes = [secret_string]
  }
}
