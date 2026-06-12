# Security Group do Load Balancer (Público)
resource "aws_security_group" "lb_sg" {
  name        = "fintech-lb-sg"
  description = "Permite trafego HTTP publico para o Load Balancer"
  vpc_id      = aws_vpc.fintech_vpc.id

  # Ingress: O que entra
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Qualquer um na internet pode acessar
  }

  # Egress: O que sai
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Pode responder para qualquer lugar
  }
}

# Security Group da API da Fintech (Privado)
resource "aws_security_group" "api_sg" {
  name        = "fintech-api-sg"
  description = "Permite trafego APENAS vindo do Load Balancer"
  vpc_id      = aws_vpc.fintech_vpc.id

  ingress {
    from_port       = 8080 # Porta onde a sua app Python roda dentro do container
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id] # SÓ entra tráfego se vier do LB!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Pode sair via NAT Gateway para atualizar
  }
}
