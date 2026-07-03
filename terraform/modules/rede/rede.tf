# --- 1. A VPC ---
resource "aws_vpc" "fintech_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "fintech-${var.env}-vpc"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

# --- 2. As Subnets ---
resource "aws_subnet" "public_zone_a" {
  vpc_id                  = aws_vpc.fintech_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { 
    Name = "fintech-${var.env}-public-1a" 
    Type = "Public"
  }
}

resource "aws_subnet" "private_zone_a" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}a"

  tags = { 
    Name = "fintech-${var.env}-private-1a" 
    Type = "Private"
  }
}

# --- 3. Internet & NAT Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fintech_vpc.id
  tags   = { Name = "fintech-${var.env}-igw" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_zone_a.id

  tags = { Name = "fintech-${var.env}-nat" }
}

# --- 4. Rotas e Associações ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fintech_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "fintech-${var.env}-public-rt" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.fintech_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "fintech-${var.env}-private-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_zone_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_zone_a.id
  route_table_id = aws_route_table.private_rt.id
}
