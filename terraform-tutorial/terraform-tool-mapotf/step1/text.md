# 第一步：部署 VPC 模块并观察标签漂移

## 查看配置

进入工作目录，查看 main.tf：

```
cd /root/workspace
cat main.tf
```

配置使用 terraform-aws-modules/vpc/aws v5.16.0 创建一个 VPC，包含公有和私有子网，并设置了 Project 和 ManagedBy 两个标签。

## 部署 VPC

```
terraform apply -auto-approve
```

Terraform 通过 VPC 模块创建了一组 EC2 网络资源（VPC、子网、路由表、网关等）。

查看创建的 VPC 及其标签：

```
awslocal ec2 describe-vpcs --output json | head -30
```

此时 VPC 只有我们在配置中声明的标签。

## 等待自动标签生效

实验环境中有一个后台脚本（模拟 AWS 合规策略），每 5 秒检查一次所有 VPC，给没有 compliance-team 标签的 VPC 自动打上标签。等待几秒：

```
sleep 10
```

再次查看 VPC 标签：

```
awslocal ec2 describe-vpcs --output json | head -50
```

现在多了两个标签：compliance-team = security 和 auto-tagged-at = ... 这些是外部策略自动添加的，不在 Terraform 配置中。

## 观察漂移

运行 terraform plan：

```
terraform plan
```

Terraform 检测到标签漂移——plan 显示要移除 compliance-team 和 auto-tagged-at 标签（因为这些标签不在配置中，Terraform 认为它们是"多余的"）。

这就是问题所在：

- 你不能修改 VPC 模块的源码添加 ignore_changes（否则无法随模块升级）
- Terraform 不支持从外部传入 ignore_changes（lifecycle 块不接受变量）
- 每次 plan 都有 drift，无法判断是否有真正需要关注的变更
- 如果执行 apply，合规策略马上又会把标签加回来，形成无限循环

## 查看模块内部代码

看看 VPC 模块中 aws_vpc 资源的完整定义：

```
sed -n '/^resource "aws_vpc"/,/^}/p' .terraform/modules/vpc/main.tf
```

可以看到 aws_vpc 资源没有 lifecycle 块。虽然模块中其他资源（如 network ACL）可能有 ignore_changes，但 aws_vpc 本身没有——模块作者无法预知每个用户需要忽略哪些属性。

下一步我们用 mapotf 来解决这个问题。
