# 第二步：查看计划文件

## 计划文件是二进制格式

先生成一份保存的计划文件：

```
cd /root/workspace
cp /root/updated-main.tf main.tf
terraform plan -out=tfplan
```

我们在 main.tf 中新增了一个 aws_s3_bucket_versioning 资源，plan 应显示 1 to add。

尝试直接查看计划文件的内容：

```
cat tfplan | head -5
```

输出是乱码——计划文件是 Terraform 专用的二进制格式，不是人类可读的文本。

## 用 show 解读计划文件

terraform show 能将计划文件渲染为与 terraform plan 终端输出相同的人类可读格式：

```
terraform show tfplan
```

输出包含资源变更摘要，用 +、~、- 标记创建、修改、销毁操作，以及每个属性的变更前后对比。

## 将计划导出为文本记录

在 CI/CD 中，通常需要将计划结果以文本形式记录到审计日志或 PR 评论中。结合 -no-color 避免 ANSI 转义序列：

```
terraform show -no-color tfplan > plan-review.txt
cat plan-review.txt
```

这份纯文本记录可以附加到 CI 制品、PR 评论或审计系统中。

## 执行计划并再次查看状态

执行计划，然后对比 show 输出的变化：

```
terraform apply tfplan
```

计划执行完毕后，查看更新后的状态：

```
terraform show | grep -A 5 "aws_s3_bucket_versioning"
```

可以看到新增的 versioning 资源已出现在状态中。

清理计划文件和文本记录：

```
rm -f tfplan plan-review.txt
```

进入下一步学习 JSON 格式输出。
