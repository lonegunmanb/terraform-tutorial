# 第二步：传参与输出引用

在这一步中，你将学习如何向模块传递参数、如何引用模块的输出值，以及模块间如何通过输出传递数据。我们继续使用 Terraform Registry 的社区模块——这次是 terraform-aws-modules/s3-bucket/aws。

## 查看代码

```bash
cd /root/workspace/step2
cat main.tf
```

这段代码展示了模块传参和输出引用的核心用法。

## 向模块传递参数

下面例子里的 module 块中除了 source 和 version 之外的参数，都会传递给模块的 variable 定义：

```hcl
module "data_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket        = "${var.project}-${var.environment}-data"
  force_destroy = true

  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "data"
  }
}
```

这里 bucket、force_destroy 和 tags 对应模块中的 variable 定义。

社区模块的输入变量说明可以在 Terraform Registry 页面查看。这个 S3 模块有 70 多个输入变量，但大多数都有默认值，实际调用时只需传入少数几个。

传参规则：
- 没有 default 值的 variable 是必填参数——调用时必须提供
- 有 default 值的 variable 是可选参数——不传则使用默认值
- 传入的值类型必须与 variable 的 type 约束匹配

在这个 S3 模块中，bucket 是可选的（不传会自动生成随机名称），tags 也有默认值 {}。force_destroy 默认为 false，我们显式设为 true 以便实验结束后能顺利销毁。

## 初始化并执行

因为使用了 Registry 模块，init 会从远程下载模块代码：

```bash
terraform init
```

注意输出中的 Downloading 行——Terraform 下载了 S3 模块到本地。

```bash
terraform plan
```

观察 plan 输出——两个模块实例各创建一个 S3 桶及相关资源（如 public access block、ownership controls 等），名称分别由变量组合而成。对比之前的本地模块只创建一个 aws_s3_bucket 资源，社区模块帮我们配置了更完善的安全默认值。

```bash
terraform apply -auto-approve
```

## 引用模块输出

模块的输出值通过 module.<模块名>.<输出名> 引用。注意社区模块的输出名与自定义模块不同——S3 模块的输出以 s3_bucket_ 为前缀：

```hcl
output "data_bucket_id" {
  value = module.data_bucket.s3_bucket_id
}
```

查看当前所有输出：

```bash
terraform output
```

你会看到 data_bucket_id、data_bucket_arn、logs_bucket_id 和 all_bucket_ids 四个输出。

## 在其他资源中使用模块输出

模块输出不仅能在根模块的 output 中展示，还可以在其他资源的配置中直接引用。试试添加一个新资源，使用之前模块的输出值：

```bash
cat >> main.tf <<'EOF'

# 演示：在资源中引用模块输出
resource "aws_s3_bucket" "combined_report" {
  bucket = "${module.data_bucket.s3_bucket_id}-report"
  tags = {
    Source = module.data_bucket.s3_bucket_arn
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

注意 combined_report 桶的名称使用了 module.data_bucket.s3_bucket_id 的值作为前缀，tags 中引用了 module.data_bucket.s3_bucket_arn。这就是在资源中引用模块输出的方式——同样的语法也可以用于将一个模块的输出传给另一个模块作为输入参数。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- module 块中的参数对应模块中的 variable 定义
- 没有 default 的 variable 是必填参数，有 default 的是可选参数
- 社区模块通常提供大量可选参数和合理的默认值，只需传入少数必要参数
- 通过 module.<名称>.<输出> 引用模块的 output 值——注意不同模块的输出名称可能不同
- 模块输出可以传给其他模块或资源，形成模块间的数据流
- 根模块的 variable 可以通过 -var 或 .tfvars 文件覆盖

完成后继续下一步。
