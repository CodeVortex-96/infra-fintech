# 2. Subnet Pública (Onde o tráfego da internet bate primeiro)
resource "aws_subnet" "public_zone_a" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = "10.0.1.0/24" # Bloco isolado (254 IPs)
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true # Permite IPs públicos aqui

  tags = { Name = "fintech-public-1a" }
}

# 3. Subnet Privada (Onde a aplicação e os dados moram)
resource "aws_subnet" "private_zone_a" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = "10.0.10.0/24" # Totalmente separado da pública
  availability_zone = "us-east-1a"

  tags = { Name = "fintech-private-1a" }
}

# 4. Internet Gateway (Para a subnet pública conversar com o mundo)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fintech_vpc.id
  tags   = { Name = "fintech-igw" }
}

# 5. NAT Gateway (Para a aplicação privada baixar atualizações sem se expor)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_zone_a.id # O NAT precisa estar na pública

  tags = { Name = "fintech-nat" }
}
