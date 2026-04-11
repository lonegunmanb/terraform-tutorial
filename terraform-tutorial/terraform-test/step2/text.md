# 第二步：集成测试——apply 模式创建真实资源

## plan vs apply

上一步的测试全部使用 command = plan，只验证配置逻辑而不创建资源。但有些验证必须在资源创建后才能进行——例如检查 AWS 实际分配的属性、验证输出值等。

创建一个集成测试文件：

```
cat > tests/integration.tftest.hcl <<'EOF'
variables {
  app_name    = "inttest"
  environment = "dev"
  suffix      = "int"
}

run "create_and_verify" {
  command = apply

  assert {
    condition     = aws_s3_bucket.app.bucket == "inttest-dev-app-int"
    error_message = "app 桶名不正确"
  }

  assert {
    condition     = aws_s3_bucket.logs.bucket == "inttest-dev-logs-int"
    error_message = "logs 桶名不正确"
  }

  assert {
    condition     = aws_dynamodb_table.sessions.billing_mode == "PAY_PER_REQUEST"
    error_message = "DynamoDB 应使用按需计费模式"
  }
}
EOF
```

运行这个集成测试：

```
terraform test -filter=tests/integration.tftest.hcl
```

这次 Terraform 会真正创建资源（通过 LocalStack），验证断言后自动销毁。注意 apply 模式比 plan 模式慢，因为需要等待资源创建和销毁。

## 验证输出值

接下来验证 outputs 是否正确。在 integration.tftest.hcl 末尾追加：

```
cat >> tests/integration.tftest.hcl <<'EOF'

run "check_outputs" {
  command = apply

  assert {
    condition     = output.app_bucket == "inttest-dev-app-int"
    error_message = "app_bucket 输出值不正确"
  }

  assert {
    condition     = output.logs_bucket == "inttest-dev-logs-int"
    error_message = "logs_bucket 输出值不正确"
  }

  assert {
    condition     = output.sessions_table == "inttest-dev-sessions"
    error_message = "sessions_table 输出值不正确"
  }
}
EOF
```

运行测试：

```
terraform test -filter=tests/integration.tftest.hcl
```

注意第二个 run 块 check_outputs 使用的是第一个 run 块 create_and_verify 创建后的状态。由于两个 run 块都没有指定 module 块，它们共享同一个主配置状态文件。第二个 run 块执行 apply 时，因为配置和状态一致，Terraform 显示 "No changes"，但仍然可以检查输出值。

## 使用 AWS CLI 额外验证

集成测试的强大之处在于可以配合其他工具进行端到端验证。先查看测试前后 S3 桶的状态：

```
awslocal s3 ls
```

现在没有桶存在（测试已自动销毁）。再次运行测试，注意测试过程中资源会被创建然后销毁：

```
terraform test -filter=tests/integration.tftest.hcl -verbose
```

-verbose 模式下可以看到完整的 apply 输出和资源创建/销毁过程。

## 多 run 块的顺序执行

run 块之间可以传递状态。创建一个测试文件，演示先创建资源、再修改、最后验证：

```
cat > tests/lifecycle.tftest.hcl <<'EOF'
variables {
  app_name    = "lctest"
  environment = "dev"
  suffix      = "lc"
}

run "initial_deploy" {
  command = apply

  assert {
    condition     = output.app_bucket == "lctest-dev-app-lc"
    error_message = "初始部署的桶名不正确"
  }
}

run "change_environment" {
  command = apply

  variables {
    environment = "staging"
  }

  assert {
    condition     = output.app_bucket == "lctest-staging-app-lc"
    error_message = "切换到 staging 后桶名应更新"
  }

  assert {
    condition     = output.sessions_table == "lctest-staging-sessions"
    error_message = "切换到 staging 后表名应更新"
  }
}
EOF
```

运行：

```
terraform test -filter=tests/lifecycle.tftest.hcl
```

第一个 run 块创建 dev 环境的资源，第二个 run 块覆盖 environment 为 staging，Terraform 会在已有状态上执行变更（替换资源名称）。测试结束后所有资源自动销毁。
