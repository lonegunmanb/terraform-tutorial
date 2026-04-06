# 第三步：部分配置 (Partial Configuration)

在前面的步骤中，我们把所有后端参数（包括凭据）直接写在了 main.tf 里。在真实项目中，这样做有安全隐患——凭据会被提交到版本控制系统中。

Terraform 提供了**部分配置**（Partial Configuration）机制：在代码中只声明后端类型和非敏感参数，将敏感或环境相关的参数推迟到 terraform init 阶段再提供。

## 查看当前状态

step3 目录有一份使用本地后端的 Terraform 代码（尚未 apply）。我们将从这里开始演示部分配置。

```bash
cd /root/workspace/step3
cat main.tf
```

## 方式一：通过配置文件提供参数

先修改 main.tf，添加一个空的 S3 后端声明：

```bash
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # 只声明后端类型，参数留空
    # 剩余参数通过 -backend-config 在 init 时提供
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
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "partial-config-bucket"
  tags = {
    Name      = "Demo Bucket"
    ManagedBy = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.app.bucket
}
EOF
```

注意 backend "s3" 块几乎是空的——只声明了使用 S3 后端，没有任何具体参数。

创建一个后端配置文件，包含所有后端参数：

```bash
cat > backend.s3.tfbackend <<'EOF'
bucket                      = "terraform-state-bucket"
key                         = "partial-demo/terraform.tfstate"
region                      = "us-east-1"
access_key                  = "test"
secret_key                  = "test"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
use_path_style              = true
skip_s3_checksum            = true
skip_region_validation      = true

endpoints = {
  s3 = "http://localhost:4566"
}
EOF
```

推荐的命名约定是 *.backendname.tfbackend，例如 backend.s3.tfbackend。

使用 -backend-config 参数初始化：

```bash
terraform init -backend-config=backend.s3.tfbackend
```

初始化成功后，apply 创建资源：

```bash
terraform apply -auto-approve
```

验证状态已存储到 S3：

```bash
awslocal s3 ls s3://terraform-state-bucket/partial-demo/
terraform plan
```

输出应显示 No changes。

## 方式二：通过命令行键值对提供参数

先回退到本地后端：

```bash
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
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "partial-config-bucket"
  tags = {
    Name      = "Demo Bucket"
    ManagedBy = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.app.bucket
}
EOF
terraform init -migrate-state <<< "yes"
```

重新添加空的 backend 块：

```bash
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
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
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "partial-config-bucket"
  tags = {
    Name      = "Demo Bucket"
    ManagedBy = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.app.bucket
}
EOF
```

这次通过命令行键值对提供参数：

```bash
terraform init \
  -backend-config="bucket=terraform-state-bucket" \
  -backend-config="key=cli-demo/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=test" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="use_path_style=true" \
  -backend-config="skip_s3_checksum=true" \
  -backend-config="skip_region_validation=true"
```

当提示迁移时输入 yes。

验证：

```bash
awslocal s3 ls s3://terraform-state-bucket/cli-demo/
terraform plan
```

## 对比两种方式

| 方式 | 适用场景 | 安全性 |
|------|---------|--------|
| -backend-config=FILE | CI/CD 流水线，参数固定 | 文件可加密存储 |
| -backend-config="KEY=VALUE" | 临时调试或简单场景 | 命令可能留在 shell 历史中 |

在实际项目中，推荐使用配置文件方式，并结合 .gitignore 排除 *.tfbackend 文件，避免将凭据提交到版本控制系统。

## 关键点

- 部分配置允许将后端参数从代码中分离——代码中只声明 backend "s3" {}，参数在 init 时提供
- -backend-config=FILE 适合 CI/CD 场景，不同环境使用不同的配置文件
- -backend-config="KEY=VALUE" 适合临时调试，但不推荐用于敏感信息
- *.tfbackend 文件不应提交到版本控制系统
