# 第二步：配置 S3 后端

在上一步中，我们用本地后端创建了两个 S3 存储桶，其中 terraform-state-bucket 就是为远程后端准备的。现在我们将状态迁移到这个桶中，并亲手体验**状态锁定**的作用。

## 确认当前状态

确认当前 Terraform 使用本地后端管理着资源：

```bash
cd /root/workspace
terraform state list
```

你应该看到 aws_s3_bucket.demo 和 aws_s3_bucket.state——状态目前存储在本地 terraform.tfstate 文件中。

## 修改配置，添加 S3 后端

用以下命令替换 main.tf，添加 S3 后端配置（含 DynamoDB 锁定）。注意资源定义保持不变，只是在 terraform 块中新增了 backend "s3"：

```bash
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"

    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_region_validation      = true

    endpoints = {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
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

resource "aws_s3_bucket" "demo" {
  bucket = "demo-app-bucket"
  tags = {
    Name      = "Demo Bucket"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "terraform-state-bucket"
  tags = {
    Name      = "Terraform State Bucket"
    ManagedBy = "Terraform"
  }
}

output "demo_bucket" {
  value = aws_s3_bucket.demo.bucket
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}
EOF
```

注意 backend "s3" 块中的关键配置：
- bucket 指向上一步创建的 terraform-state-bucket
- key 指定状态文件在桶中的路径
- dynamodb_table 指定用于状态锁定的 DynamoDB 表

## 迁移状态到 S3

运行 terraform init，Terraform 会检测到后端配置变更：

```bash
terraform init
```

当提示 Do you want to migrate all workspaces to "s3"? 时，输入 yes 并回车。Terraform 会将本地 terraform.tfstate 中的状态数据迁移到 S3 桶中。

## 验证迁移结果

确认状态已存储到 S3：

```bash
awslocal s3 ls s3://terraform-state-bucket/demo/
```

你应该能看到 terraform.tfstate 文件——状态已经从本地迁移到了远程存储。

确认 Terraform 仍能正常管理资源：

```bash
terraform plan
```

输出应显示 No changes——迁移对资源管理没有任何影响。

## 体验状态锁定

状态锁定的作用是：当一个 Terraform 操作正在执行时，其他操作无法同时修改状态，避免冲突和数据损坏。

我们用一个 time_sleep 资源让 terraform apply 阻塞 30 秒，在这段时间内观察锁的存在。先添加 time_sleep 资源：

```bash
cat >> main.tf <<'EOF'

resource "time_sleep" "lock_demo" {
  create_duration = "30s"
}
EOF
```

环境中预置了一个演示脚本 show-lock.sh，它会自动完成以下操作：

1. 后台启动 terraform apply
2. 轮询等待 Terraform 获取锁
3. 查询 DynamoDB 锁表并展示锁的详细信息（LockID、Operation、Who、Created）
4. 尝试并发执行 terraform plan——你会看到锁冲突错误
5. 等待 apply 完成，确认锁被自动释放

运行脚本：

```bash
bash ./show-lock.sh
```

观察输出，你会看到以下关键信息：

**DynamoDB 锁表内容** — 锁记录中包含：
- LockID：状态文件路径（terraform-state-bucket/demo/terraform.tfstate）
- Info：JSON 数据，记录了谁持有锁、执行的操作类型、锁的创建时间

**锁冲突错误** — 尝试并发 terraform plan 时会报错：

```
Error: Error acquiring the state lock

Terraform acquires a state lock to protect the state from being
written by multiple users at the same time.

Lock Info:
  ID:        ...
  Path:      terraform-state-bucket/demo/terraform.tfstate
  Operation: OperationTypeApply
```

这正是状态锁定在保护你——它阻止了并发操作，确保同一时间只有一个 Terraform 进程能修改状态。

**锁释放** — apply 完成后锁表记录数变为 0，说明 Terraform 自动释放了锁。

## 清理 time_sleep

time_sleep 仅用于演示锁定，现在将它从配置中移除：

```bash
sed -i '/^resource "time_sleep"/,/^}/d' main.tf
terraform apply -auto-approve
```

确认状态干净：

```bash
terraform plan
```

输出应显示 No changes。

## 关键点

- S3 后端将状态存储在远程 S3 存储桶中，团队成员可以共享
- 状态存储桶由上一步的 Terraform 代码创建，是一个普通的 S3 存储桶
- dynamodb_table 参数启用基于 DynamoDB 的状态锁定，防止并发操作冲突
- Terraform 在执行 apply/destroy 等修改操作时自动获取锁，完成后自动释放
- 持有锁期间，其他 Terraform 操作会立即报错，避免状态被破坏
