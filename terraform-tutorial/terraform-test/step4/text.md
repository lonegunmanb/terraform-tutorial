# 第四步：综合练习——自己编写测试

现在轮到你自己动手了！请根据以下要求编写测试文件并运行通过。

## 练习 1：边界值测试

创建测试文件 tests/boundary.tftest.hcl，要求：

1. 编写一个 run 块，使用 command = plan，传入 app_name = "a1"（最短合法名称，2 字符），断言两个桶和表的命名都正确。
2. 编写一个 run 块，传入 app_name = "abcdefghijklmnopqrstu"（最长合法名称，21 字符），同样断言命名正确。
3. 编写一个 run 块，使用 expect_failures 验证 app_name = "AB-invalid"（大写字母开头）被 validation 拒绝。

提示：这三个测试验证的是变量校验规则的边界情况。

编写完成后运行：

```
terraform test -filter=tests/boundary.tftest.hcl
```

确认三个 run 块全部通过。

---

## 练习 2：跨环境标签一致性

创建测试文件 tests/consistency.tftest.hcl，要求：

1. 编写一个 run 块，使用 command = plan 和 environment = "prod"，断言所有三个资源（app 桶、logs 桶、sessions 表）的 Environment 标签都等于 "prod"。
2. 在同一个 run 块中，断言 ManagedBy 标签都等于 "Terraform"。
3. 追加一个新的 run 块，覆盖 environment = "staging"，验证标签也相应更新为 "staging"。

编写完成后运行：

```
terraform test -filter=tests/consistency.tftest.hcl
```

---

## 练习 3：集成测试 + 输出验证

创建测试文件 tests/e2e.tftest.hcl，要求：

1. 第一个 run 块使用 command = apply，传入自定义变量值，创建真实资源。
2. 第二个 run 块使用 command = plan 验证三个 output 值分别符合预期格式（包含你设定的 app_name 和 environment）。
3. 至少有一个断言使用 startswith 或 endswith 函数检查桶名的前缀或后缀。

提示：

- startswith(string, prefix) 检查字符串是否以指定前缀开头
- endswith(string, suffix) 检查字符串是否以指定后缀结尾

编写完成后运行：

```
terraform test -filter=tests/e2e.tftest.hcl
```

---

## 练习 4（附加挑战）：Mock 模式与 override_resource

创建测试文件 tests/advanced_mock.tftest.hcl，要求：

1. 使用 mock_provider "aws" 块，并在其中用 mock_resource 为 aws_dynamodb_table 提供自定义 arn 默认值。
2. 编写一个 run 块，使用 command = apply，断言 DynamoDB 表的 arn 等于你指定的值。
3. 编写另一个 run 块，使用 run 块内部的 override_resource 覆盖 aws_s3_bucket.app 的 arn 值，断言该 arn 等于你覆盖的值。

编写完成后运行：

```
terraform test -filter=tests/advanced_mock.tftest.hcl
```

---

## 验证所有测试

全部编写完后，运行完整测试套件：

```
terraform test
```

确认所有测试文件和 run 块全部绿色通过。

如果遇到失败，使用 -verbose 参数查看详细输出来定位问题：

```
terraform test -verbose -filter=tests/<失败的文件>.tftest.hcl
```

---

## 参考答案

如果你卡住了，以下是练习 1 的参考答案，可以对照检查思路：

```
cat <<'HINT'
# tests/boundary.tftest.hcl 参考

variables {
  environment = "dev"
  suffix      = "b"
}

run "shortest_valid_name" {
  command = plan

  variables {
    app_name = "a1"
  }

  assert {
    condition     = aws_s3_bucket.app.bucket == "a1-dev-app-b"
    error_message = "最短合法 app_name 桶名不正确"
  }
}

run "longest_valid_name" {
  command = plan

  variables {
    app_name = "abcdefghijklmnopqrstu"
  }

  assert {
    condition     = aws_s3_bucket.app.bucket == "abcdefghijklmnopqrstu-dev-app-b"
    error_message = "最长合法 app_name 桶名不正确"
  }
}

run "uppercase_rejected" {
  command = plan

  variables {
    app_name = "AB-invalid"
  }

  expect_failures = [
    var.app_name,
  ]
}
HINT
```

其他练习的思路类似，参照前三步中学到的模式即可完成。
