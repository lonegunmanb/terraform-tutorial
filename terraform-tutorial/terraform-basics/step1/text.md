# 第一步：创建一台 EC2 实例

## 初始化并应用

进入工作目录，查看预置的 `main.tf` 配置文件：

```bash
cd /root/workspace
cat main.tf
```

这份配置定义了一台 `t2.micro` 类型的 EC2 实例。接下来，初始化 Terraform 并创建它：

```bash
terraform init
terraform apply -auto-approve
```

`terraform init` 会下载 AWS Provider 插件；`terraform apply` 会真正创建资源。

执行完成后，你应该能看到类似输出：

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-xxxxxxxxxx"
instance_type = "t2.micro"
```

## 用 awslocal 验证

`awslocal` 是 LocalStack 提供的 AWS CLI 封装，它自动将请求指向本地的 LocalStack 端点（`http://localhost:4566`），不需要手动指定 `--endpoint-url`。

用它查询刚创建的 EC2 实例：

```bash
awslocal ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags]" \
  --output table
```

你应该能看到一台状态为 `running`、类型为 `t2.micro` 的实例，Tags 中包含 `Name: TerraformTutorial`。

> 💡 `awslocal` 等价于 `aws --endpoint-url=http://localhost:4566`，在 LocalStack 环境下使用它更加方便。
