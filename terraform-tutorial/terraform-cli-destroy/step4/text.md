# 第四步：依赖顺序销毁——time_sleep 与 depends_on 实战

## 真实案例：IAM 角色的最终一致性

在真实的 AWS 环境中，IAM 是全球服务，角色创建后需要数秒到数十秒才能在所有区域完全生效（最终一致性）。如果另一个资源在角色未传播完成时就引用了它的 ARN，AWS API 会返回错误：

```
Invalid policy document. Please check the policy syntax
and ensure that Principals are valid.
```

这是一个已知问题（参考 https://github.com/hashicorp/terraform-provider-aws/issues/29392 ）。即使 Terraform 通过资源引用建立了隐式依赖，IAM 的最终一致性仍然会导致首次 apply 失败、第二次才成功的情况。

解决方案是使用 time_sleep 资源强制等待传播完成。这不仅保证了创建时的正确顺序，也确保了销毁时先删除引用方（bucket policy），再删除被引用方（IAM role）。

## 查看配置

进入预先准备好的 depends-demo 目录：

```
cd /root/workspace/depends-demo
cat main.tf
```

配置中有 4 个资源，依赖链如下：

```
aws_iam_role.app
       │
       ▼
time_sleep.iam_propagation (等待 10 秒)
       │
       ▼
aws_s3_bucket_policy.access ──→ aws_s3_bucket.data
```

关键设计：

- time_sleep 通过 depends_on 显式依赖 IAM role
- time_sleep.triggers 中存储 role_arn，供下游资源引用
- bucket policy 通过 time_sleep.triggers["role_arn"] 获取角色 ARN（而非直接引用 aws_iam_role.app.arn）

这样 Terraform 的依赖图就包含了 time_sleep 节点，强制在 role 创建后等待 10 秒再创建 policy。

## 观察创建顺序

```
terraform apply -auto-approve
```

仔细观察输出中的时间线：

1. aws_iam_role.app 和 aws_s3_bucket.data 并行创建（互不依赖）
2. time_sleep.iam_propagation 开始等待——注意 Terraform 打印 "Still creating..." 每隔几秒一次，直到 10 秒过去
3. aws_s3_bucket_policy.access 最后创建（等 time_sleep 完成后才开始）

如果跳过 time_sleep 直接引用 aws_iam_role.app.arn，Terraform 会在 role 创建完成后立刻创建 policy——在真实 AWS 上大概率触发 "Invalid principal" 错误。

## 查看依赖图

```
terraform graph | grep '\->' | grep -v provider | grep -v '\[root\]'
```

注意 time_sleep 节点同时作为 role 和 policy 之间的桥梁。

## 观察销毁顺序

```
terraform destroy -auto-approve
```

观察 Destroying... 行的顺序：

1. aws_s3_bucket_policy.access 最先销毁（叶子节点）
2. time_sleep.iam_propagation 随后销毁
3. aws_s3_bucket.data 和 aws_iam_role.app 并行销毁（已无其他资源依赖它们）

销毁顺序严格遵循依赖链的逆序。这保证了：

- Bucket policy 在 IAM role 之前被删除——如果反过来，policy 中就会引用一个已不存在的 principal
- 在真实 AWS 中，如果先删 role 再删 policy，后续对 bucket 的访问控制可能处于不确定状态

## 为什么不能去掉 time_sleep

你可能会想：既然 bucket policy 通过 aws_iam_role.app.arn 已经有了隐式依赖，为什么还需要 time_sleep？

原因有两个：

1. 创建时：隐式依赖只保证"role 创建完成后才创建 policy"，但不保证"role 在 AWS 内部已传播完成"。time_sleep 的 create_duration 填补了这个时间差
2. 销毁时：time_sleep 通过 depends_on 建立的依赖链确保了严格的逆序销毁——先删使用方，等一会（虽然 destroy 不会真的等 create_duration），再删被使用方

这就是 depends_on 与 time_sleep 的典型组合模式：解决云服务的最终一致性问题，同时保证创建和销毁的正确顺序。

## 清理

```
cd /root/workspace
rm -rf depends-demo
```
