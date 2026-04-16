# 第二步：按架构层级拆分模块

## 查看模块化后的结构

```bash
cd /root/workspace/step2
find . -name "*.tf" | sort
```

你会看到五个模块，每个对应三层架构的一个层级：

```
./modules/networking/    ← 网络层：VPC、子网、路由
./modules/web/           ← Web 层：ALB、安全组
./modules/data/          ← 数据层：DynamoDB
./modules/storage/       ← 存储层：S3 静态资源、备份
./modules/security/      ← 安全层：IAM、Secrets Manager
./main.tf                ← 根模块：组装各层
```

## 理解网络层模块

```bash
cat modules/networking/main.tf
```

注意 count 的使用——用一个数组变量同时创建多个子网，而不是重复写 4 个 resource 块。这在三层架构中尤其重要：你可能有 2 个、3 个甚至 6 个可用区。

```bash
cat modules/networking/outputs.tf
```

网络层输出 vpc_id 和子网 ID 列表——这是其他层的基础依赖。

## 理解 Web 层模块

```bash
cat modules/web/main.tf
```

Web 层包含 ALB 和三组安全组（ALB / App / Data），它们之间的引用链清晰可见：

```
ALB SG: 0.0.0.0/0:80 入站
App SG: 仅允许来自 ALB SG 的 80
Data SG: 仅允许来自 App SG 的 5432
```

这是三层架构安全隔离的核心，现在全部收纳在一个模块里，逻辑一目了然。

## 查看根模块如何组装

```bash
cat main.tf
```

注意模块间的依赖流：

```
networking → vpc_id, subnet_ids
    ↓
web(vpc_id, public_subnet_ids) → alb_dns, security_group_ids
    ↓
storage → bucket_arns     ──┐
data → table_arn ──────────┼→ security(所有 ARN) → iam_role
ssm, cloudwatch ─────────────┘
```

每一层只依赖它需要的输入——网络层不知道有 S3，数据层不知道有 ALB。

## 部署模块化版本

```bash
terraform init
terraform plan
```

观察 plan 输出——现在每个资源前都带有 module 前缀，层级归属一目了然。

```bash
terraform apply -auto-approve -parallelism=2
```

## 验证模块化部署

```bash
terraform state list
```

注意层次化的资源地址：

```
module.networking.aws_vpc.this
module.networking.aws_subnet.public[0]
module.web.aws_lb.this
module.web.aws_security_group.alb
module.web.aws_ecs_cluster.app
module.web.aws_ecs_service.app
module.data.aws_dynamodb_table.users
module.storage.aws_s3_bucket.static
module.security.aws_iam_role.app
```

谁属于哪一层，一看便知。

```bash
terraform output
```

## 对比：单体 vs 模块化

| 维度 | 单体（step1） | 模块化（step2） |
|------|-------------|---------------|
| 定位资源 | 在 500 行里搜索 | 进入对应层的模块目录 |
| 安全组逻辑 | 散落在文件中间 | 集中在 web 模块里 |
| 修改影响 | 可能误伤其他层 | 限定在单个模块内 |
| 权限控制 | 全有或全无 | 网络团队只改 networking |
| 独立测试 | 必须全量 apply | 单层独立验证 |

下一步，我们把手写的网络层替换为社区验证的 VPC 模块。在进入下一步之前，先清理资源释放 MiniStack 内存：

```bash
terraform destroy -auto-approve -parallelism=2
```
