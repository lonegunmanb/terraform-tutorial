# 第一步：观察大模块——三层架构的反面教材

## 看看这个"大泥球"

进入第一个工作目录，查看这个把整套三层架构塞进一个文件的配置：

```bash
cd /root/workspace/step1
wc -l main.tf
```

将近 500 行代码——VPC、子网、安全组、ALB、DynamoDB、SQS、SNS、S3、IAM、Secrets Manager、CloudWatch——全部混在一起。

## 浏览各层资源

```bash
head -100 main.tf
```

先看网络层：VPC、4 个子网（2 公有 + 2 私有）、互联网网关、路由表。

```bash
sed -n '147,212p' main.tf
```

再看安全组：ALB 安全组、App 安全组、Data 安全组。注意它们之间的引用链：ALB 允许外部 80 端口 → App 只允许来自 ALB 的 8080 → Data 只允许来自 App 的 5432。

这是三层架构安全隔离的核心——但在一个文件里，这些引用关系散落在几百行之间。

## 部署并查看

```bash
terraform plan
```

plan 输出有多少行？你能快速分辨哪些资源属于网络层、哪些属于 Web 层吗？

```bash
terraform apply -auto-approve -parallelism=2
```

## 验证各层资源

```bash
awslocal ec2 describe-vpcs --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock}' --output table
awslocal ec2 describe-subnets --query 'Subnets[].{ID:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}' --output table
awslocal elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName}' --output table
awslocal s3 ls
awslocal sqs list-queues
awslocal dynamodb list-tables
awslocal iam list-roles --query 'Roles[].RoleName'
```

资源都创建成功了。现在想象几个场景：

**场景一**：安全审计要求你梳理安全组规则——谁能访问谁。在 500 行里，安全组散落在中间位置，你需要反复跳转才能理清引用链。

**场景二**：网络团队只负责 VPC 和子网，但这个文件里还有 IAM 策略和 DynamoDB 表。他们被迫拥有不需要的修改权限。

**场景三**：改 ALB 监听器端口时，你不小心改了同一行附近的安全组规则，plan 输出几十行，你没注意到那一行变更。

## 查看状态文件

```bash
terraform state list
```

所有资源地址都是扁平的。你能一眼看出哪些属于网络层、哪些属于 Web 层、哪些属于数据层吗？

## 大模块在三层架构下的五个问题

| 问题 | 在三层架构中的表现 |
|------|-----------------|
| 慢 | plan 需要查询所有层的所有资源状态 |
| 不安全 | 改数据层需要网络层和安全层的权限 |
| 高风险 | 改 ALB 配置时可能误动安全组或 S3 |
| 难理解 | 网络/Web/数据/存储/安全混在一起 |
| 难测试 | 要测数据层，必须连带部署整个 VPC |

下一步，我们按架构层级把这个单体拆开。在进入下一步之前，先清理资源释放 LocalStack 内存：

```bash
terraform destroy -auto-approve -parallelism=2
```
