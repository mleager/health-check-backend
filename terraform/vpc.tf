resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC"
  }
}

resource "aws_subnet" "public" {
  count = length(var.vpc.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.vpc.public_subnets[count.index]
  availability_zone       = var.vpc.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public ${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.vpc.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.private_subnets[count.index]
  availability_zone = var.vpc.azs[count.index]

  tags = {
    Name = "Private ${count.index}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "EIP"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public RT"
  }

}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "Private RT"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.vpc.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.vpc.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

