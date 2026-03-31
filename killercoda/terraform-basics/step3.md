# 第三步：应用变更 (Apply)

确认 plan 符合预期后，执行 apply 将变更应用到环境：

```bash
terraform apply -auto-approve
```

> `-auto-approve` 跳过了交互式确认，在生产环境中建议去掉此参数。

执行完成后，你应该能看到：
- **"Apply complete! Resources: 1 added, 0 changed, 0 destroyed."**
- 输出变量 `bucket_name = "my-terraform-tutorial-bucket"`

验证 S3 存储桶是否真的被创建了：

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

🎉 恭喜！你已经完成了 Terraform 的核心三步流！
