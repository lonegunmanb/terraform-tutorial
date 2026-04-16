# 第三步：引入社区模块——站在巨人肩膀上

## 为什么网络层最适合用社区模块

自制的 modules/networking 能运行，但它很基础：
- 没有 NAT Gateway（私有子网出网）
- 没有 VPC Flow Logs（网络审计）
- 没有灵活的多 AZ 扩展
- 没有处理各种边界情况

terraform-aws-modules/vpc 是社区最流行的 VPC 模块（GitHub 5000+ Stars），经过大量生产环境验证，一行参数就能开启 NAT、Flow Logs、VPN 等高级特性。MiniStack 明确支持该模块 v5.x/v6.x。

## 查看更新后的网络层

```bash
cd /root/workspace/step3
cat modules/networking/main.tf
```

与 step2 对比：

```bash
diff /root/workspace/step2/modules/networking/main.tf modules/networking/main.tf
```

核心变化：
- 7 个手写的 resource 块被一个 module 调用替代
- VPC、子网、IGW、路由表全部由社区模块内部管理
- 只需要传入 CIDR 和可用区列表

再看 outputs：

```bash
diff /root/workspace/step2/modules/networking/outputs.tf modules/networking/outputs.tf
```

outputs 使用社区模块的输出（module.vpc.vpc_id、module.vpc.public_subnets）。而 variables.tf 完全不变——Web 层和其他模块不需要修改任何代码。

## 下载社区模块

```bash
terraform init
```

观察 Terraform 从 Registry 下载 terraform-aws-modules/vpc：

```
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws ...
```

## 部署并验证

```bash
terraform plan
```

plan 输出显示 module.networking.module.vpc.* 嵌套地址——模块嵌套调用的正常表现。

```bash
terraform apply -auto-approve -parallelism=2
```

验证网络资源：

```bash
awslocal ec2 describe-vpcs --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock}' --output table
awslocal ec2 describe-subnets --query 'Subnets[].{ID:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}' --output table
awslocal elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName}' --output table
```

## 版本选择策略

```bash
grep version modules/networking/main.tf
```

~> 5.0 意味着 >= 5.0, < 6.0——允许 5.x 系列的 patch/minor 升级，但不会拉入 6.0 的 breaking change。

## 确认外部接口不变

```bash
terraform output
```

输出与 step2 完全一致。网络层内部实现从 7 个 resource 变成 1 个 module 调用，但 web 模块、data 模块、security 模块都不需要改一行代码。

下一步，我们在各层模块里加入内置防护——让配置错误在部署之前就被拦截。
