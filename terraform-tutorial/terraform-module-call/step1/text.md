# 第一步：模块来源与版本约束

在这一步中，你将学习如何从 Terraform Registry 调用社区模块，以及如何使用 version 约束锁定模块版本。我们以 terraform-aws-modules/vpc/aws 这个广泛使用的 VPC 模块为例。

## module 块的基本语法

调用模块的语法是 module 块：

```hcl
module "名称" {
  source  = "模块来源"
  version = "版本约束"
  # 传入参数...
}
```

其中 source 是唯一的必填参数，它告诉 Terraform 去哪里加载模块代码。

## 查看 VPC 模块调用

进入工作目录，查看预置的代码：

```bash
cd /root/workspace/step1
cat main.tf
```

这段代码使用了 Terraform Registry 作为模块来源，调用了社区维护的 VPC 模块：

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

关键参数说明：

- source 使用 Registry 格式：namespace/name/provider，即 terraform-aws-modules/vpc/aws
- version 精确锁定为 6.6.1，生产环境中使用明确的版本是明智选择，确保在任何环境下代码是一致的
- 其余参数（name、cidr、azs 等）是传给模块的输入变量

## terraform init 与模块下载

调用远程模块时，必须先运行 terraform init 来下载模块代码：

```bash
terraform init
```

注意输出中的 Downloading 行——Terraform 从 Registry 下载了 VPC 模块到本地的 .terraform/modules/ 目录。

查看下载的模块元数据：

```bash
cat .terraform/modules/modules.json | python3 -m json.tool
```

可以看到模块的来源、版本、本地存储路径等信息。

## 执行 VPC 模块

运行 plan 查看模块将创建哪些资源：

```bash
terraform plan
```

观察 plan 输出——你会看到资源地址形如 module.vpc.aws_vpc.this[0]、module.vpc.aws_subnet.public[0] 等。所有资源都归属在 vpc 模块命名空间下。

VPC 模块仅用几行配置就声明了 VPC、子网、路由表等一整套网络基础设施，这正是模块复用的价值。

执行 apply 创建资源：

```bash
terraform apply -auto-approve
```

查看创建的 VPC 和子网：

```bash
awslocal ec2 describe-vpcs --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock}' --output table
awslocal ec2 describe-subnets --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}' --output table
```

## source 支持的来源类型

除了 Terraform Registry，source 还支持以下来源（了解即可）：

**本地路径**

```hcl
module "my_bucket" {
  source = "../modules/s3-bucket"
}
```

本地路径以 ./ 或 ../ 开头。Terraform 直接从文件系统加载模块代码，不需要下载。后续步骤中我们会使用本地模块。

**GitHub**

```hcl
module "example" {
  source = "github.com/hashicorp/example?ref=v2.0.0"
}
```

**通用 Git 仓库**

```hcl
module "example" {
  source = "git::https://example.com/module.git?ref=main"
}
```

**S3 Bucket**

```hcl
module "example" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/module.zip"
}
```

## version 约束语法

当使用 Terraform Registry 来源时，可以用 version 参数锁定模块版本：

```hcl
# 精确版本
module "vpc_exact" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"
}

# 版本范围
module "vpc_range" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 6.0, < 7.0"
}

# 悲观约束（>= 6.6, < 7.0）
module "vpc_pessimistic" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"
}
```

version 约束只适用于 Registry 来源。本地路径不支持 version；Git 来源通过 ref 参数指定分支或 tag。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- source 是 module 块的必填参数，指定模块代码的来源
- Registry 来源格式为 namespace/name/provider，支持 version 约束
- 本地路径以 ./ 或 ../ 开头，无需下载
- Git 来源通过 ref 参数指定版本（分支或 tag）
- 新增或修改 source 后必须重新执行 terraform init
- 社区模块（如 terraform-aws-modules/vpc/aws）封装了复杂的基础设施配置，大幅减少重复代码，并且一般情况下它们都是经过测试和实战验证的

完成后继续下一步。
