# 第一步：模块来源与版本约束

在这一步中，你将了解 module 块的 source 参数支持的各种来源类型，以及如何使用 version 约束锁定模块版本。

## module 块的基本语法

调用模块的语法是 module 块：

```hcl
module "名称" {
  source = "模块来源"
  # 传入参数...
}
```

其中 source 是唯一的必填参数，它告诉 Terraform 去哪里加载模块代码。

## 查看本地模块调用

进入工作目录，查看已有的代码：

```bash
cd /root/workspace/step1
cat main.tf
```

这里使用了**本地路径**作为 source：

```hcl
module "my_bucket" {
  source      = "../modules/s3-bucket"
  bucket_name = "source-demo-bucket"
}
```

本地路径以 ./ 或 ../ 开头。Terraform 直接从文件系统加载模块代码，不需要下载。

查看被调用的模块代码：

```bash
echo "=== variables.tf ==="
cat ../modules/s3-bucket/variables.tf

echo "=== main.tf ==="
cat ../modules/s3-bucket/main.tf

echo "=== outputs.tf ==="
cat ../modules/s3-bucket/outputs.tf
```

## 执行本地模块调用

```bash
terraform plan
```

观察 plan 输出——资源地址为 module.my_bucket.aws_s3_bucket.this，说明资源属于 my_bucket 模块实例。

```bash
terraform apply -auto-approve
awslocal s3 ls
```

## source 支持的来源类型

除了本地路径，source 还支持以下来源（了解即可，本实验使用本地路径）：

**Terraform Registry（注册表）**

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}
```

这是最常用的远程来源。格式为 namespace/name/provider。可以配合 version 参数锁定版本。

**GitHub**

```hcl
module "example" {
  source = "github.com/hashicorp/example"
}

# 指定分支或 tag
module "example_v2" {
  source = "github.com/hashicorp/example?ref=v2.0.0"
}
```

**通用 Git 仓库**

```hcl
module "example" {
  source = "git::https://example.com/module.git"
}

module "example_ssh" {
  source = "git::ssh://git@example.com/module.git?ref=main"
}
```

**S3 Bucket**

```hcl
module "example" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/module.zip"
}
```

## version 约束

当使用 Terraform Registry 来源时，可以用 version 参数锁定模块版本：

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"           # 精确版本
}

module "vpc_range" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0, < 6.0"  # 版本范围
}

module "vpc_pessimistic" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"          # >= 5.0, < 6.0
}
```

version 约束只适用于 Registry 来源。本地路径和 Git 来源不支持 version 参数——Git 来源通过 ref 参数指定分支或 tag。

## terraform init 与模块下载

每次新增或修改 module 的 source 后，都需要运行 terraform init 来下载或更新模块：

```bash
terraform init
```

对于本地模块，init 只是建立符号链接；对于远程模块，init 会将模块代码下载到 .terraform/modules/ 目录。

查看模块缓存：

```bash
cat .terraform/modules/modules.json | python3 -m json.tool
```

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- source 是 module 块的必填参数，指定模块代码的来源
- 本地路径以 ./ 或 ../ 开头，无需下载
- Registry 来源格式为 namespace/name/provider，支持 version 约束
- Git 来源通过 ref 参数指定版本（分支或 tag）
- 新增或修改 source 后必须重新执行 terraform init

完成后继续下一步。
