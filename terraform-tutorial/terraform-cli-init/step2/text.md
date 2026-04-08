# 第二步：Provider 锁文件与 -upgrade

## 重复初始化的幂等性

terraform init 可以安全地重复执行。如果工作目录已初始化，再次运行只会验证现有 provider：

```
cd /root/workspace
terraform init
```

观察输出，你会看到 "Reusing previously-installed hashicorp/null" — provider 不会被重复下载。

## 强制升级 Provider

使用 -upgrade 参数重新检查是否有更新的 provider 版本，并更新锁文件：

```
terraform init -upgrade
```

Terraform 会重新解析版本约束（~> 3.0）并下载当前符合约束的最新版本。如果已是最新版本，内容不变；如果有更新版本，锁文件会被更新。

## 对比锁文件的变化

查看锁文件，观察版本号和哈希值是否有变化：

```
cat .terraform.lock.hcl
```

## 在 CI 中保护锁文件

在 CI/CD 管道中，通常要求不允许 CI 自动修改锁文件（版本锁应由开发者手动审查后提交），可以使用 -lockfile=readonly：

```
terraform init -lockfile=readonly
```

该模式的行为：

- 使用锁文件中记录的版本下载 provider（不检查是否有更新）
- 如果 provider 已在缓存中，仅验证校验和
- 如果需要更新锁文件（例如锁文件缺失某个 provider），操作会直接报错

故意触发只读模式的报错场景：先删除锁文件，再用 readonly 模式初始化：

```
rm .terraform.lock.hcl
terraform init -lockfile=readonly
```

你会看到类似 "The lock file does not contain a valid checksum" 或初始化失败的报错，这正是 CI 环境所期望的保护行为。

恢复锁文件：

```
terraform init
```

## 小结

| 命令 | 适用场景 |
|------|---------|
| terraform init | 开发时首次初始化或已有锁文件后的常规初始化 |
| terraform init -upgrade | 手动升级 provider 版本，需将更新后的锁文件提交代码库 |
| terraform init -lockfile=readonly | CI/CD 管道，防止流水线自动修改锁文件 |
