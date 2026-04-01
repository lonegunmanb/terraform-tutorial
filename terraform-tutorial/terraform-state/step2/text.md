# 第二步：漂移检测

当有人绕过 Terraform 直接修改了资源（比如在 AWS 控制台手动改了标签），就会产生**漂移**（Drift）——真实环境与 Terraform 代码描述的期望状态不一致。

让我们模拟一次漂移，看看 Terraform 如何发现它。

## 确认当前状态一致

先运行 `plan` 确认当前没有差异：

```bash
cd /root/workspace
terraform plan
```

你应该看到 `No changes`——代码、状态文件、真实环境三者完全一致。

## 在 Terraform 外部修改资源

用 `awslocal`（LocalStack 的 AWS CLI 封装）直接给 S3 存储桶添加一个新标签，模拟有人在 AWS 控制台手动操作：

```bash
awslocal s3api put-bucket-tagging --bucket my-app-data-bucket --tagging 'TagSet=[{Key=Name,Value=Data Bucket},{Key=Environment,Value=Lab},{Key=ManagedBy,Value=Terraform},{Key=CostCenter,Value=12345}]'
```

验证标签已被修改：

```bash
awslocal s3api get-bucket-tagging --bucket my-app-data-bucket
```

你应该能看到多出了一个 `CostCenter: 12345` 标签——这个标签不在 Terraform 代码中。

## Terraform 发现漂移

再次运行 `plan`：

```bash
terraform plan
```

Terraform 检测到了漂移！它发现真实环境中的标签与代码中定义的不一致，会生成一个计划来**移除**那个手动添加的 `CostCenter` 标签，将资源恢复到代码描述的期望状态。

注意输出中的 `~` 符号，表示资源将被**就地修改**（in-place update）。

## 修复漂移

执行 `apply` 让 Terraform 修复漂移：

```bash
terraform apply -auto-approve
```

用 `awslocal` 验证标签已恢复：

```bash
awslocal s3api get-bucket-tagging --bucket my-app-data-bucket
```

`CostCenter` 标签已被移除，资源回到了代码描述的状态。

> 💡 这就是 Terraform 状态管理的核心价值：**Terraform 通过状态文件作为记忆，对比代码与真实环境，自动发现并修复漂移**。这使得 `terraform plan` 不仅是一个部署工具，更是一个持续的合规检查工具。

✅ 你已经亲手体验了漂移检测和修复的完整流程。
