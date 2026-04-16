# 网络层：VPC、子网、互联网网关、路由表
# 对应三层架构中的网络基础设施——公有子网放 ALB，私有子网放应用和数据

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.app_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.app_name}-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = zipmap(var.public_subnet_cidrs, var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.key
  availability_zone = each.value

  tags = {
    Name = "${var.app_name}-${var.environment}-public-${each.value}"
  }
}

resource "aws_subnet" "private" {
  for_each = zipmap(var.private_subnet_cidrs, var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.key
  availability_zone = each.value

  tags = {
    Name = "${var.app_name}-${var.environment}-private-${each.value}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
