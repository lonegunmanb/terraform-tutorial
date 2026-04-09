terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ── 第 0 层：VPC（最底层，无依赖）──
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "demo-vpc" }
}

# ── 第 1 层：子网和安全组（依赖 VPC）──
resource "aws_subnet" "web" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags       = { Name = "web-subnet" }
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-sg" }
}

# ── 第 1 层（带显式依赖）：db 子网依赖 web 子网 ──
resource "aws_subnet" "db" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags       = { Name = "db-subnet" }

  # 显式依赖：确保 db 子网在 web 子网之后创建、之前销毁
  # 模拟场景：db 子网中的服务依赖 web 子网中的网关
  depends_on = [aws_subnet.web]
}

# ── 第 2 层：实例（依赖子网和安全组）──
resource "aws_instance" "web" {
  ami                    = "ami-00000000000000001"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web.id]
  tags                   = { Name = "web-server" }
}
