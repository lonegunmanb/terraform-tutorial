# 第四步：依赖顺序销毁——VPC 网络资源实战

## 为什么销毁顺序重要

在真实的 AWS 环境中，很多资源在被其他资源引用时无法直接删除。例如：

- VPC 有子网时不能删除
- 子网中有实例时不能删除
- 安全组被实例引用时不能删除

Terraform 通过资源间的依赖关系自动计算正确的销毁顺序，确保先删除"使用方"再删除"被使用方"。

## 创建 VPC 网络资源

创建一个新目录，用来演示网络资源的依赖关系：

```
mkdir -p /root/workspace/vpc-demo && cd /root/workspace/vpc-demo
```

编写包含多层依赖关系的配置文件：

```
cat > main.tf <<'EOF'
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
EOF
```

依赖关系如下（箭头表示"依赖于"）：

```
aws_instance.web ──→ aws_subnet.web ──→ aws_vpc.main
       │                    ↑
       │          aws_subnet.db (depends_on)
       │
       └──────→ aws_security_group.web ──→ aws_vpc.main
```

## 观察创建顺序

```
terraform init
terraform apply -auto-approve
```

仔细观察创建过程中的输出顺序：

1. aws_vpc.main 最先创建（无依赖）
2. aws_subnet.web 和 aws_security_group.web 并行创建（都只依赖 VPC）
3. aws_subnet.db 在 web 子网完成后才创建（depends_on）
4. aws_instance.web 最后创建（依赖子网和安全组）

## 查看依赖图

用 terraform graph 输出依赖关系，筛选资源间的边：

```
terraform graph | grep '\->' | grep -v provider | grep -v '\[root\]'
```

可以看到 Terraform 内部维护的完整依赖图，每条 -> 连线代表一个依赖关系。

## 观察销毁顺序

现在执行销毁，重点关注 Destroying... 行的输出顺序：

```
terraform destroy -auto-approve
```

观察输出，销毁顺序与创建顺序完全相反：

1. aws_instance.web 最先销毁（叶子节点，没有其他资源依赖它）
2. aws_subnet.db 随后销毁（它 depends_on web 子网，必须先于 web 子网销毁）
3. aws_subnet.web 和 aws_security_group.web 并行销毁（实例和 db 子网已清除）
4. aws_vpc.main 最后销毁（所有子网和安全组都已清除）

在真实 AWS 中，如果 Terraform 尝试在实例仍在运行时删除子网，AWS API 会返回 DependencyViolation 错误。正是因为 Terraform 严格按依赖逆序操作，才避免了这类问题。

## depends_on 的销毁影响

上面的 db 子网与 web 子网之间没有资源引用关系（它们只是在同一个 VPC 中的两个子网），但因为 depends_on 的存在，Terraform 保证了：

- 创建时：web 子网 → db 子网（先创建 web）
- 销毁时：db 子网 → web 子网（先销毁 db）

这在以下场景中至关重要：db 子网中运行的数据库服务通过 web 子网中的 NAT 网关访问外网。如果先删了 web 子网（NAT 网关随之消失），db 子网中的服务可能无法正常关闭连接，导致资源残留或删除失败。

## 清理

```
cd /root/workspace
rm -rf vpc-demo
```
