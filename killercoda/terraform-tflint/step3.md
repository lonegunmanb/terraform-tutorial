# 第三步：验证修复结果

再次运行 TFLint：

```bash
tflint
```

如果所有问题都已修复，你应该看到没有任何告警或错误输出。

接着验证代码仍然可以正常工作：

```bash
terraform init
terraform plan
```

`plan` 应该正常输出变更预览，没有语法或配置错误。

🎉 你已经学会了使用 TFLint 检查和修复 Terraform 代码质量问题！
