# 第四步：内置防护与版本固定

## 三层架构为什么需要防护

在三层架构中，每一层的配置错误可能引发连锁反应：
- 网络层的 CIDR 格式写错 → VPC 创建失败 → 所有层全部瘫痪
- Web 层只传了 1 个子网给 ALB → 负载均衡没有跨 AZ 冗余 → 单点故障
- 数据层的消息保留时长设错 → 任务丢失 → 数据不一致
- 存储层的桶名太短 → AWS API 报错 → 部署中断

内置防护让这些错误在部署之前就被拦截。

```bash
cd /root/workspace/step4
```

## 1. validation 块：网络层的 CIDR 格式校验

```bash
cat modules/networking/variables.tf
```

vpc_cidr 变量有 validation 块，使用 can(cidrhost(...)) 检查格式合法性。试试传一个非法值：

```bash
terraform plan -var="vpc_cidr=not-a-cidr"
```

立刻报错，不需要 AWS API 调用。再试一个有效值：

```bash
terraform plan -var="vpc_cidr=172.16.0.0/16"
```

同时，数据层的 message_retention_seconds 也有 validation：

```bash
terraform plan -var="message_retention_seconds=30"
```

## 2. precondition 块：Web 层的高可用检查

```bash
cat modules/web/main.tf | grep -A5 precondition
```

ALB 的 precondition 检查传入的子网数量是否 >= 2。这是三层架构高可用的基本要求——ALB 必须跨至少两个可用区。

这种跨变量的约束（subnet 列表的长度）是 validation 做不到的，因为 validation 只能引用当前变量本身。

同样，存储层检查 app_name 和 environment 组合后的桶名长度：

```bash
cat modules/storage/main.tf | grep -A5 precondition
```

试试触发存储层的 precondition：

```bash
terraform plan -var="app_name=x"
```

## 3. postcondition 块：数据层的行为保证

```bash
cat modules/data/main.tf | grep -A5 postcondition
```

DynamoDB 表的 postcondition 验证 apply 后的实际结果——确保计费模式是 PAY_PER_REQUEST。

```bash
terraform apply -auto-approve -parallelism=2
```

## 4. 版本固定：让部署可重现

```bash
head -10 main.tf
```

required_version = ">= 1.5, < 2.0"——允许所有 1.x，拒绝 2.0 进入。

```bash
cat .terraform.lock.hcl | head -20
```

锁文件记录了实际下载的 provider 版本和哈希值。提交到版本控制后，任何机器的 terraform init 都会得到相同版本。

## 三层防护对比

```bash
grep -rn "validation\|precondition\|postcondition" modules/
```

| 工具 | 触发时机 | 可引用的内容 | 本实验示例 |
|------|---------|------------|----------|
| validation | plan 之前 | 仅当前变量 | CIDR 格式、消息保留时长 |
| precondition | apply 之前 | 多个变量、表达式 | ALB 子网数 >= 2、桶名长度 |
| postcondition | apply 之后 | self.*（当前资源） | DynamoDB 计费模式保证 |

## 最终验证

```bash
terraform state list
terraform output
```

与第一步的 500 行单体相比，现在这套三层架构：
- 五个模块各司其职，对应架构的五个层级
- 网络层使用社区 VPC 模块，久经生产验证
- 关键约束内嵌在各层——CIDR 格式、子网数量、桶名规范、计费模式
- provider 和模块版本有明确约束，部署可重现

恭喜完成本实验的所有步骤！
