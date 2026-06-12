# 1. Tabela de rotas para a Subnet Pública (Aponta direto para o Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fintech_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Significa: qualquer tráfego para a Internet externa
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "fintech-public-rt" }
}

# 2. Associa a Subnet Pública a essa tabela de rotas
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_zone_a.id
  route_table_id = aws_route_table.public_rt.id
}

# 3. Tabela de rotas para a Subnet Privada (Joga o tráfego externo para o NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.fintech_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id # Aqui está a segurança!
  }

  tags = { Name = "fintech-private-rt" }
}

# 4. Associa a Subnet Privada a essa tabela de rotas
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_zone_a.id
  route_table_id = aws_route_table.private_rt.id
}
