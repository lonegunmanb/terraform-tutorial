# 第三步：辅助模块、expect_failures 与 Mock Provider

## 辅助模块 (Helper Module)

辅助模块让你可以在测试前创建前置资源、或在测试后通过数据源验证结果。

创建一个 setup 辅助模块，用于生成唯一的桶名前缀：

```
mkdir -p tests/setup
```

```
cat > tests/setup/main.tf <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "prefix" {
  type    = string
  default = "test"
}

resource "aws_s3_bucket" "setup_bucket" {
  bucket = "${var.prefix}-setup-bucket"
  tags = {
    Purpose = "test-setup"
  }
}

output "setup_bucket_name" {
  value = aws_s3_bucket.setup_bucket.bucket
}
EOF
```

新增模块后需要重新初始化，让 Terraform 发现它：

```
terraform init
```

现在创建一个使用辅助模块的测试：

辅助模块运行时会独立初始化 Provider。由于主配置的 provider 块不会自动传递给辅助模块的 run 块，我们需要在测试文件中显式配置 Provider，让所有 run 块都能连接 LocalStack：

```
cat > tests/with_helper.tftest.hcl <<'EOF'
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

variables {
  app_name    = "helpertest"
  environment = "dev"
  suffix      = "hlp"
}

run "setup" {
  module {
    source = "./tests/setup"
  }

  variables {
    prefix = "helpertest"
  }

  assert {
    condition     = output.setup_bucket_name == "helpertest-setup-bucket"
    error_message = "setup 模块桶名不正确"
  }
}

run "deploy_main" {
  command = apply

  assert {
    condition     = output.app_bucket == "helpertest-dev-app-hlp"
    error_message = "主配置桶名不正确"
  }
}
EOF
```

运行测试：

```
terraform test -filter=tests/with_helper.tftest.hcl
```

Terraform 先运行 setup 辅助模块创建前置桶，再运行主配置。两者有独立的状态文件。测试结束后按逆序销毁——先销毁主配置资源，再销毁 setup 模块的资源。

## expect_failures：测试错误分支

好的测试不仅验证正确路径，还要验证错误输入被正确拒绝。variables.tf 中定义了 environment 和 app_name 的 validation 块，我们来测试它们：

```
cat > tests/validation.tftest.hcl <<'EOF'
run "valid_environment" {
  command = plan

  variables {
    environment = "dev"
    app_name    = "myapp"
    suffix      = "v"
  }
}

run "invalid_environment_rejected" {
  command = plan

  variables {
    environment = "test"
    app_name    = "myapp"
    suffix      = "v"
  }

  expect_failures = [
    var.environment,
  ]
}

run "invalid_app_name_rejected" {
  command = plan

  variables {
    environment = "dev"
    app_name    = "123invalid"
    suffix      = "v"
  }

  expect_failures = [
    var.app_name,
  ]
}

run "empty_app_name_rejected" {
  command = plan

  variables {
    environment = "dev"
    app_name    = "x"
    suffix      = "v"
  }

  expect_failures = [
    var.app_name,
  ]
}
EOF
```

运行：

```
terraform test -filter=tests/validation.tftest.hcl
```

四个 run 块全部通过：第一个验证合法值被接受，后三个验证非法值被 validation 块正确拒绝。注意 expect_failures 列出的是应当失败的可检查对象（这里是变量 var.environment 和 var.app_name）。

## Mock Provider

Mock Provider 让你无需连接真实云服务即可测试配置逻辑。mock_provider 会返回与真实 Provider 相同的 Schema，但不调用任何 API。

创建一个使用 Mock Provider 的测试：

```
cat > tests/mock.tftest.hcl <<'EOF'
mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-bucket"
    }
  }

  mock_resource "aws_dynamodb_table" {
    defaults = {
      arn = "arn:aws:dynamodb:us-east-1:000000000000:table/mock-table"
    }
  }
}

variables {
  app_name    = "mockapp"
  environment = "dev"
  suffix      = "mock"
}

run "mock_naming" {
  command = apply

  assert {
    condition     = aws_s3_bucket.app.bucket == "mockapp-dev-app-mock"
    error_message = "Mock 模式下桶名不正确"
  }

  assert {
    condition     = aws_s3_bucket.app.arn == "arn:aws:s3:::mock-bucket"
    error_message = "Mock 模式下 ARN 应为指定默认值"
  }
}

run "mock_output" {
  command = apply

  assert {
    condition     = output.app_bucket == "mockapp-dev-app-mock"
    error_message = "Mock 模式下输出值不正确"
  }

  assert {
    condition     = output.sessions_table == "mockapp-dev-sessions"
    error_message = "Mock 模式下 sessions 表名不正确"
  }
}
EOF
```

运行 Mock 测试：

```
terraform test -filter=tests/mock.tftest.hcl
```

注意 Mock 测试的速度比集成测试快得多，因为不需要与 LocalStack 交互。mock_provider 模式下 Terraform 不会创建任何真实资源，所有计算属性（如 arn）使用你指定的默认值或自动生成的假数据。

## 查看所有测试

运行全部测试，确认一切正常：

```
terraform test
```

应该看到所有测试文件全部通过。
