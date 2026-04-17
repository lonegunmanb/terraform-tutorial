# 第四步：提取安全层并加入防护

## 完成模块化：安全层

查看安全模块：

```bash
cat /root/stage/step4/modules/security/main.tf
```

安全模块封装了 Secrets Manager 凭证和 IAM 角色/策略——三层架构的横切关注点。

查看新增的 moved 块：

```bash
diff /root/workspace/moved.tf /root/stage/step4/moved.tf
```

最后 6 个资源搬进 module.security。

## 加入内置防护

除了安全模块，这次更新还为已有模块加入了防护机制。先看看有哪些变化：

```bash
diff /root/workspace/modules/networking/variables.tf /root/stage/step4/modules/networking/variables.tf
```

网络层：vpc_cidr 变量增加了 validation 块，用 can(cidrhost(...)) 确保 CIDR 格式合法。

```bash
diff /root/workspace/modules/web/main.tf /root/stage/step4/modules/web/main.tf
```

Web 层：ALB 增加了 precondition 块，确保至少传入 2 个子网（跨 AZ 高可用）。

```bash
diff /root/workspace/modules/storage/variables.tf /root/stage/step4/modules/storage/variables.tf
```

存储层：app_name 变量增加了 validation 块，校验名称至少 3 个字符。

```bash
diff /root/workspace/modules/data/main.tf /root/stage/step4/modules/data/main.tf
```

数据层：postcondition 块，验证 DynamoDB 表的计费模式是 PAY_PER_REQUEST。

## 应用最终重构

```bash
cp -r /root/stage/step4/modules/* /root/workspace/modules/
cp /root/stage/step4/main.tf /root/workspace/
cp /root/stage/step4/moved.tf /root/workspace/
terraform init
```

## 验证零变更

```bash
terraform plan
```

安全层的 moved 搬迁完美完成——已有资源 0 to add, 0 to change, 0 to destroy。validation / precondition / postcondition 的加入也不影响已有资源。

```bash
terraform apply -auto-approve -parallelism=2
```

## 测试内置防护

试试传一个非法 CIDR：

```bash
terraform plan -var="vpc_cidr=not-a-cidr"
```

立刻报错，不需要调用 AWS API。再试一个有效值确认能通过：

```bash
terraform plan -var="vpc_cidr=172.16.0.0/16"
```

## 三层防护对比

| 工具 | 触发时机 | 可引用的内容 | 本实验示例 |
|------|---------|------------|----------|
| validation | plan 之前 | 仅当前变量 | CIDR 格式、桶名长度 |
| precondition | apply 之前 | 多个变量、表达式 | ALB 子网数 >= 2 |
| postcondition | apply 之后 | self.*（当前资源） | DynamoDB 计费模式 |

## 最终成果

```bash
terraform state list
```

```bash
wc -l main.tf
```

从第一步的 450+ 行单体，到现在不到 120 行的根模块 + 五个职责清晰的子模块。全过程通过 moved 块完成，没有销毁、没有重建一个资源。

```bash
cat moved.tf | grep "moved {" | wc -l
```

总计 24 个 moved 块，覆盖了所有从单体到五层模块化的资源地址迁移。

## 版本固定

查看收紧后的版本约束：

```bash
head -3 main.tf
```

required_version = ">= 1.5, < 2.0" 确保团队所有人使用同一大版本的 Terraform，避免 2.0 的 breaking change 意外进入。
