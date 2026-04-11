# 第一步：plan 模式断言与变量覆盖

## 查看项目结构

进入工作目录，了解当前配置：

```
cd /root/workspace
ls -la
```

可以看到 main.tf、variables.tf、outputs.tf 和 docker-compose.yml。打开 main.tf 查看配置——它创建了两个 S3 桶和一个 DynamoDB 表，资源名称由变量拼接而成。

```
cat variables.tf
```

注意 environment 变量有 validation 块，只允许 dev、staging、prod 三个值；app_name 也有正则校验。

## 创建第一个测试文件

创建 tests 目录并编写第一个测试文件：

```
mkdir -p tests
```

```
cat > tests/basic.tftest.hcl <<'EOF'
# 使用文件级变量为所有 run 块提供默认值
variables {
  app_name    = "testapp"
  environment = "dev"
  suffix      = "unit"
}

run "check_bucket_naming" {
  command = plan

  assert {
    condition     = aws_s3_bucket.app.bucket == "testapp-dev-app-unit"
    error_message = "app 桶命名规则不正确"
  }

  assert {
    condition     = aws_s3_bucket.logs.bucket == "testapp-dev-logs-unit"
    error_message = "logs 桶命名规则不正确"
  }
}

run "check_dynamodb_naming" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.sessions.name == "testapp-dev-sessions"
    error_message = "DynamoDB 表命名规则不正确"
  }

  assert {
    condition     = aws_dynamodb_table.sessions.hash_key == "SessionID"
    error_message = "DynamoDB hash_key 应为 SessionID"
  }
}
EOF
```

## 运行测试

执行测试命令：

```
terraform test
```

Terraform 搜索 tests/ 目录中的 .tftest.hcl 文件，按顺序执行 run 块。每个 run 块使用 command = plan，所以不会创建任何真实资源——这就是单元测试模式。

输出应该类似：

```
tests/basic.tftest.hcl... in progress
  run "check_bucket_naming"... pass
  run "check_dynamodb_naming"... pass
tests/basic.tftest.hcl... tearing down
tests/basic.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

## 变量覆盖

在同一测试文件中，不同的 run 块可以覆盖文件级变量。在 tests/basic.tftest.hcl 末尾追加一个新的 run 块：

```
cat >> tests/basic.tftest.hcl <<'EOF'

run "override_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_s3_bucket.app.bucket == "testapp-prod-app-unit"
    error_message = "覆盖 environment 后桶名应包含 prod"
  }

  assert {
    condition     = aws_dynamodb_table.sessions.name == "testapp-prod-sessions"
    error_message = "覆盖 environment 后表名应包含 prod"
  }
}
EOF
```

再次运行测试：

```
terraform test
```

现在应该看到三个 run 块全部通过。注意 override_environment 使用了 variables 块覆盖文件级的 environment 变量为 "prod"，而 app_name 和 suffix 仍然继承文件级的值。

## 使用 -verbose 查看详情

添加 -verbose 参数可以看到每个 run 块的完整 plan 输出：

```
terraform test -verbose
```

这在调试失败的测试时非常有用。

## 使用 -filter 运行指定文件

当测试文件很多时，可以用 -filter 只运行指定文件：

```
terraform test -filter=tests/basic.tftest.hcl
```

## 验证标签

创建一个新的测试文件，专门验证标签逻辑：

```
cat > tests/tags.tftest.hcl <<'EOF'
variables {
  app_name    = "tagtest"
  environment = "staging"
  suffix      = "t"
}

run "check_common_tags" {
  command = plan

  assert {
    condition     = aws_s3_bucket.app.tags["Environment"] == "staging"
    error_message = "Environment 标签应为 staging"
  }

  assert {
    condition     = aws_s3_bucket.app.tags["App"] == "tagtest"
    error_message = "App 标签应为 tagtest"
  }

  assert {
    condition     = aws_s3_bucket.app.tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy 标签应为 Terraform"
  }
}

run "all_resources_share_tags" {
  command = plan

  assert {
    condition     = aws_s3_bucket.app.tags["Environment"] == aws_s3_bucket.logs.tags["Environment"]
    error_message = "app 和 logs 桶的 Environment 标签应一致"
  }

  assert {
    condition     = aws_s3_bucket.app.tags["App"] == aws_dynamodb_table.sessions.tags["App"]
    error_message = "S3 桶和 DynamoDB 表的 App 标签应一致"
  }
}
EOF
```

运行所有测试：

```
terraform test
```

现在应该有两个测试文件、五个 run 块全部通过。
