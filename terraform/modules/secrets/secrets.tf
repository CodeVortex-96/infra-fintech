variable "env" {
  description = "Ambiente (prod, staging, dev)"
  type        = string
  validation {
    condition     = contains(["production", "staging", "dev"], var.env)
    error_message = "Ambiente inválido."
  }
}

# 1. Secret Manager
resource "aws_secretsmanager_secret" "api_secret" {
  name        = "fintech/api-key/${var.env}"
  description = "Chave de autenticacao da API da Fintech - Gerenciado por Terraform"
  
  # Nível Tech Lead: Rotação automática (padrão de segurança bancária)
  rotation_lambda_arn = "" # Em um caso real, aqui iria o ARN da Lambda de rotação

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.env
    Security    = "High"
  }
}

# 2. Definição do valor (Opcional, mas profissional)
# Dica: Em produção, o valor inicial é setado via CLI ou console para não ficar no terraform.tfstate
resource "aws_secretsmanager_secret_version" "api_secret_version" {
  secret_id     = aws_secretsmanager_secret.api_secret.id
  secret_string = jsonencode({
    api_key = "placeholder-value"
  })

  # Impede que alterações no código destruam a senha acidentalmente
  lifecycle {
    ignore_changes = [secret_string]
  }
}
