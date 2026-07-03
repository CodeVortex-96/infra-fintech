terraform {
  backend "s3" {
    # Nome do bucket (deve ser único globalmente na AWS)
    bucket         = "fintech-infra-terraform-state-2026"
    
    # Caminho onde o arquivo de estado ficará dentro do bucket
    key            = "prod/fintech-api/terraform.tfstate"
    
    # Região do bucket
    region         = "us-east-1"
    
    # Tabela do DynamoDB para bloqueio (State Locking)
    # Isso impede que dois engenheiros rodem o 'apply' ao mesmo tempo
    dynamodb_table = "terraform-state-lock"
    
    # Segurança extra: criptografia no lado do servidor
    encrypt        = true
  }
}
