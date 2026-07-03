# Variável exigida pelo módulo
variable "vpc_id" {
  description = "ID da VPC onde os Security Groups serão criados"
  type        = string
}

# --- 1. Security Group: Load Balancer (Público) ---
resource "aws_security_group" "lb_sg" {
  name        = "fintech-lb-sg"
  description = "Controle de acesso para o Load Balancer (Publico)"
  vpc_id      = var.vpc_id

  tags = {
    Name      = "fintech-lb-sg"
    ManagedBy = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_http_ingress" {
  security_group_id = aws_security_group.lb_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Permite HTTP publico"
}

resource "aws_vpc_security_group_egress_rule" "lb_all_egress" {
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Permite todo trafego de saida"
}

# --- 2. Security Group: API da Fintech (Privado) ---
resource "aws_security_group" "api_sg" {
  name        = "fintech-api-sg"
  description = "Acesso restrito para a API da Fintech"
  vpc_id      = var.vpc_id

  tags = {
    Name      = "fintech-api-sg"
    ManagedBy = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "api_lb_ingress" {
  security_group_id            = aws_security_group.api_sg.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lb_sg.id
  description                  = "Permite trafego apenas vindo do LB"
}

resource "aws_vpc_security_group_egress_rule" "api_nat_egress" {
  security_group_id = aws_security_group.api_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Permite saida para atualizacoes via NAT"
}
