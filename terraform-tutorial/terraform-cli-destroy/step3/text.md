# 第三步：两步销毁工作流与 destroy 后重建

## 两步销毁工作流

与 apply 类似，destroy 也支持先生成计划再执行的两步工作流。在 CI/CD 中销毁环境时，这样更安全——计划可以先经过审批再执行。

生成一份销毁计划并保存：

```
cd /root/workspace
terraform plan -destroy -out=destroy.tfplan
```

用 terraform show 查看计划内容（审批环节）：

```
terraform show destroy.tfplan
```

确认无误后执行计划（无需确认提示）：

```
terraform apply destroy.tfplan
```

输出 Destroy complete! Resources: 3 destroyed.

验证资源已全部销毁：

```
awslocal s3 ls
terraform state list
```

清理计划文件：

```
rm destroy.tfplan
```

## destroy 后重建

terraform destroy 销毁的是远端资源和 state 记录，.tf 配置文件不会被修改。因此你可以随时重新 apply 来重建所有资源：

```
terraform apply -auto-approve
```

确认三个资源已重建：

```
awslocal s3 ls
awslocal dynamodb list-tables
terraform state list
```

这个"创建-测试-销毁"循环正是 Terraform 管理临时环境（开发/测试/CI）的典型模式。

## destroy 与 apply -destroy 的等价性

terraform destroy 本质上是 terraform apply -destroy 的别名。用 apply -destroy 执行一次销毁，对比输出：

```
terraform apply -destroy -auto-approve
```

输出与 terraform destroy -auto-approve 完全相同。两种写法等价，区别仅在于语义表达：

- terraform destroy——日常使用，意图清晰
- terraform apply -destroy——CI 脚本中保持与 apply 统一的命令格式

重建资源以恢复环境：

```
terraform apply -auto-approve
awslocal s3 ls
```

确认资源就绪后进入下一步。
