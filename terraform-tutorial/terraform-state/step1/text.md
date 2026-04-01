# 第一步：探索状态文件

Terraform 的状态文件记录了它管理的所有资源。让我们来看看它到底存了什么。

## 查看已管理的资源

```bash
cd /root/workspace
terraform state list
```

你应该看到三个资源地址：
- `aws_s3_bucket.data`
- `aws_s3_bucket.logs`
- `aws_dynamodb_table.locks`

这就是 Terraform 的"管理清单"——只有出现在这个清单上的资源，Terraform 才会去追踪和管理。

## 查看资源详情

```bash
terraform state show aws_s3_bucket.data
```

注意输出中的 `id`、`arn`、`tags` 等字段——这些都是 Terraform 从 Provider 读回来的完整属性。

## 对比代码与状态文件

先看看代码中对这个存储桶的定义：

```bash
grep -A 8 'resource "aws_s3_bucket" "data"' main.tf
```

代码只声明了 `bucket` 和 `tags`——非常简洁。

现在看看状态文件中存储了什么：

```bash
terraform state show aws_s3_bucket.data
```

状态文件包含了**远比代码多**的信息：`id`、`arn`、`bucket_domain_name`、`region` 等等。这些额外信息来自 Provider 与真实环境的交互结果。

## 直接查看原始状态文件

```bash
cat terraform.tfstate | python3 -m json.tool | head -50
```

状态文件是一个 JSON 文件，核心结构包含：
- **`version`**：状态文件格式版本
- **`serial`**：每次状态更新时递增，用于并发控制
- **`resources`**：所有被管理的资源列表
- **`instances[].attributes`**：每个资源实例的完整属性

> 💡 状态文件的 `serial` 就像数据库的版本号。当使用远程后端时，Terraform 通过 `serial` 来检测冲突，防止多人同时覆盖状态。

✅ 你已经了解了状态文件的作用和结构：它是 Terraform 代码与真实环境之间的桥梁，记录的信息远比代码详细。
