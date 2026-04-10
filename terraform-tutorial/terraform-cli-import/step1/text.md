# 第一步：terraform import 命令

## 确认已有基础设施

进入工作目录，先用 awslocal 确认环境中已有若干 S3 桶（这些是通过 AWS CLI 直接创建的，不在 Terraform 管理中）：

```
cd /root/workspace
awslocal s3 ls
```

可以看到 legacy-app、legacy-logs、legacy-archive 等桶。查看 legacy-app 的标签：

```
awslocal s3api get-bucket-tagging --bucket legacy-app
```

此时 Terraform 状态是空的：

```
terraform state list
```

没有任何输出——Terraform 还不知道这些资源的存在。

## 声明资源块

要导入 legacy-app 桶，首先需要在配置中声明对应的 resource 块。先写一个最小的空块：

```
cat >> main.tf <<'EOF'

resource "aws_s3_bucket" "app" {
}
EOF
```

## 执行导入

运行 terraform import，将 legacy-app 桶导入到 aws_s3_bucket.app：

```
terraform import aws_s3_bucket.app legacy-app
```

Terraform 通过 provider 查询了远端资源的实际属性，并记录到状态中。确认资源已在状态中：

```
terraform state list
```

查看导入后的资源详情：

```
terraform state show aws_s3_bucket.app
```

## 补全配置

现在运行 plan 看看配置与状态的差异：

```
terraform plan
```

plan 可能显示要修改标签或其他属性——因为配置中的 resource 块是空的。根据 state show 的输出补全配置：

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
  s3_use_path_style           = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "legacy-app"
  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
EOF
```

再次运行 plan 验证：

```
terraform plan
```

如果显示 No changes 或仅有 Terraform 无法控制的只读属性差异，说明配置已与实际状态对齐。

## 验证 Terraform 已接管

现在可以通过 Terraform 修改这个桶。例如添加一个新标签：

```
sed -i 's/Team        = "backend"/Team        = "backend"\n    ManagedBy   = "Terraform"/' main.tf
terraform apply -auto-approve
```

通过 awslocal 验证标签已更新：

```
awslocal s3api get-bucket-tagging --bucket legacy-app
```

Terraform 已完全接管了这个桶的管理。

进入下一步学习 import 块的声明式导入。
