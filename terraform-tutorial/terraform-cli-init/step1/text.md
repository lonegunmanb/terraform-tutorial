# 第一步：初次初始化工作目录

terraform init 是 Terraform 工作流的第一步。在本步骤中，你将从一个尚未初始化的目录开始，观察 terraform init 完整的执行过程，并探索它生成的文件。

## 检查初始状态

进入工作目录，查看此时目录下只有 main.tf：

```
cd /root/workspace
ls
```

## 查看配置文件

先了解你将要初始化的配置：

```
cat main.tf
```

可以看到代码声明了 null provider（版本约束 ~> 3.0）但没有任何 backend 配置，这意味着将使用默认的本地 backend。

## 执行初次初始化

运行初始化命令：

```
terraform init
```

仔细阅读输出，你会看到三个主要阶段：

1. Initializing the backend — 初始化本地 backend
2. Initializing provider plugins — 查找并下载 null provider
3. Terraform has been successfully initialized!

## 检查生成的文件和目录

初始化完成后，目录里多了什么？

```
ls -la
```

应当看到 .terraform/ 目录和 .terraform.lock.hcl 文件。

查看 .terraform/ 目录的完整结构：

```
ls -R .terraform/
```

找到下载的 null provider 可执行文件：

```
find .terraform -name "terraform-provider-null*" -type f
```

## 查看 Provider 依赖锁文件

```
cat .terraform.lock.hcl
```

锁文件记录了：

- provider 的注册表地址（registry.terraform.io/hashicorp/null）
- 已安装的具体版本号（满足 ~> 3.0 约束）
- 该版本在不同平台上的 SHA-256 哈希值

这个文件应当提交到代码仓库，确保团队所有成员和 CI/CD 流水线使用完全相同的 provider 版本。
