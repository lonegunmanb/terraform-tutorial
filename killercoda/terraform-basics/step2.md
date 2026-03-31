# 第二步：预览变更 (Plan)

执行 `plan` 命令，Terraform 会告诉你它打算做什么——但不会真正执行：

```bash
terraform plan
```

仔细阅读输出：
- `+` 表示**将要创建**的资源
- `-` 表示**将要销毁**的资源
- `~` 表示**将要修改**的资源

你应该能看到 Terraform 计划创建一个 `aws_s3_bucket.tutorial` 资源。

> 💡 `plan` 是 Terraform 的"干跑模式"。在生产环境中，务必先 plan 再 apply！
