# 第二步：传参与输出引用

在这一步中，你将学习如何向模块传递参数、如何引用模块的输出值，以及模块间如何通过输出传递数据。

## 查看代码

```bash
cd /root/workspace/step2
cat main.tf
```

这段代码展示了模块传参和输出引用的核心用法。

## 向模块传递参数

下面例子里的 module 块中除了 source 之外的参数，都会传递给模块的 variable 定义：

```hcl
module "data_bucket" {
  source      = "../modules/s3-bucket"
  bucket_name = "${var.project}-${var.environment}-data"
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "data"
  }
}
```

这里 bucket_name 和 tags 对应模块中的两个 variable。查看模块的变量定义：

```bash
cat ../modules/s3-bucket/variables.tf
```

传参规则：
- 没有 default 值的 variable 是**必填参数**——调用时必须提供
- 有 default 值的 variable 是**可选参数**——不传则使用默认值
- 传入的值类型必须与 variable 的 type 约束匹配

注意 bucket_name 没有 default，所以必须传入；tags 有 default = {}，所以可以省略。

亲自验证一下——如果调用模块时不传必填参数会怎样？在 main.tf 末尾临时添加一个不传 bucket_name 的模块调用：

```bash
cat >> main.tf <<'EOF'

module "test_missing" {
  source = "../modules/s3-bucket"
  # 故意不传 bucket_name
}
EOF
```

```bash
terraform init
terraform plan
```

Terraform 会报错：

```
Error: Missing required argument

  The argument "bucket_name" is required, but no definition was found.
```

这就是没有 default 的 variable 的效果——调用方必须显式提供值，否则无法通过校验。

删除刚才添加的测试代码：

```bash
head -n -5 main.tf > main.tf.tmp && mv main.tf.tmp main.tf
```

## 初始化并执行

```bash
terraform init
terraform plan
```

观察 plan 输出——两个模块实例各创建一个 S3 桶，名称分别由变量组合而成。

```bash
terraform apply -auto-approve
```

## 引用模块输出

模块的输出值通过 module.<模块名>.<输出名> 引用：

```hcl
output "data_bucket_id" {
  value = module.data_bucket.bucket_id
}
```

查看当前所有输出：

```bash
terraform output
```

你会看到 data_bucket_id、data_bucket_arn、logs_bucket_id 和 all_bucket_ids 四个输出。

## 模块输出作为另一个模块的输入

模块输出最常见的用途之一是作为另一个模块的输入参数。试试添加一个新的模块调用，将之前模块的输出传进去：

```bash
cat >> main.tf <<'EOF'

# 演示：将模块输出组合后创建新资源
resource "aws_s3_bucket" "combined_report" {
  bucket = "${module.data_bucket.bucket_id}-report"
  tags = {
    Source = module.data_bucket.bucket_arn
  }
}

output "report_bucket_id" {
  value = aws_s3_bucket.combined_report.id
}
EOF
```

```bash
terraform apply -auto-approve
```

注意 combined_report 桶的名称使用了 module.data_bucket.bucket_id 的值作为前缀。这就是模块间通过输出传递数据的方式。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- module 块中的参数对应模块 variables.tf 中的 variable 定义
- 没有 default 的 variable 是必填参数，有 default 的是可选参数
- 通过 module.<名称>.<输出> 引用模块的 output 值
- 模块输出可以传给其他模块或资源，形成模块间的数据流
- 根模块的 variable 可以通过 -var 或 .tfvars 文件覆盖

完成后继续下一步。
