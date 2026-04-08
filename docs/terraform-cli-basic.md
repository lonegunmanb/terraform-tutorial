---
order: 9
title: CLI 基础命令
group: Terraform CLI
group_order: 9
---

# Terraform CLI 基础命令

Terraform 的所有功能通过单一可执行文件 `terraform` 暴露。输入 `terraform` 可查看所有可用子命令，输入 `terraform <subcommand> -help` 可查看单个子命令的详细用法。

::: info
`init`、`plan`、`apply`、`destroy`、`validate`、`show`、`output`、`state`、`import`、`providers`、`refresh`、`taint`、`untaint`、`workspace`、`test` 等核心子命令将在后续章节中各自单独讲解。本章重点介绍全局参数与其余常用命令。
:::

## 全局参数 -chdir

通常需要先 `cd` 到包含 `.tf` 文件的目录才能运行 Terraform。`-chdir` 全局参数允许不切换当前目录直接指定目标路径：

```shell
terraform -chdir=environments/production plan
```

该参数让 Terraform 在执行子命令之前切换工作目录，所有文件读写都发生在指定路径下。常用于自动化脚本和 CI/CD 流水线。

有两种情况 Terraform 会坚持使用原始工作目录：
- 处理命令行配置文件时（发生在解析 `-chdir` 之前）
- 计算 `path.cwd` 时仍返回真实当前目录；使用 `path.root` 获取 `-chdir` 指定的路径

## terraform version

检查当前安装的 Terraform 版本，同时向 HashiCorp Checkpoint 服务查询是否有新版本：

```shell
terraform version
```

### Checkpoint 服务

Terraform 会定期与 HashiCorp [Checkpoint](https://checkpoint.hashicorp.com/) 服务交互，发送不含用户身份信息的匿名数据，用于检查版本更新和关键安全公告。可以通过以下方式关闭：

- 设置环境变量 `CHECKPOINT_DISABLE=1` 完全禁用
- 在命令行配置文件中设置 `disable_checkpoint = true`（仅关闭交互）或 `disable_checkpoint_signature = true`（仅关闭匿名 ID 发送）

## 命令行自动补全

在 bash 或 zsh 中安装 Terraform 命令行自动补全：

```shell
terraform -install-autocomplete
```

安装完成后重开 shell，输入 `terraform ` 后按 Tab 键即可补全子命令名和常用参数。

卸载：

```shell
terraform -uninstall-autocomplete
```

## terraform fmt

将 `.tf` 文件格式化为 HashiCorp 标准风格（统一缩进、属性对齐、换行规范等）。强烈建议在提交代码前运行。

```shell
# 检查是否有文件需要格式化（非零退出码表示存在不规范文件）
terraform fmt -check

# 查看具体改动 diff（不修改文件）
terraform fmt -diff

# 格式化当前目录所有 .tf 文件（原地修改）
terraform fmt

# 递归格式化子目录
terraform fmt -recursive
```

::: tip
`terraform fmt -check` 非常适合放在 CI 流水线里做格式强制检查，有格式问题则构建失败。
:::

## terraform console

交互式 HCL 表达式计算器。在当前工作区的上下文中实时求值任意表达式，适合调试变量、`locals` 和内置函数：

```shell
terraform console
```

进入交互式 REPL 后可以输入任意 HCL 表达式：

```
> var.environment
"dev"
> local.name_prefix
"my-app-dev"
> length("hello world")
11
> upper("terraform")
"TERRAFORM"
> toset(["a", "b", "a"])
toset(["a", "b"])
> { for k, v in {a=1, b=2} : k => v * 2 }
{
  "a" = 2
  "b" = 4
}
```

输入 `exit` 或按 `Ctrl+D` 退出。

::: tip
`terraform console` 是理解 HCL 内置函数的最佳工具。遇到不确定某个表达式结果时，直接在 console 里试。
:::

## terraform get

下载并安装配置中 `module` 块引用的模块（仅处理模块，不涉及 Provider）：

```shell
# 下载所有引用的模块
terraform get

# 更新已安装的模块到最新兼容版本
terraform get -update
```

> `terraform init` 也会执行模块下载，但 `terraform get` 仅处理模块，速度更快，适合在只新增了 `module` 块时按需调用。

## terraform graph

生成资源依赖关系的有向图（DOT 格式输出）：

```shell
terraform graph
```

配合 [Graphviz](https://graphviz.org/) 可以渲染成图片：

```shell
terraform graph | dot -Tsvg > graph.svg
```

`-type` 参数可指定图的类型：

```shell
terraform graph -type=plan    # 计划图
terraform graph -type=apply   # 应用图
```

## terraform force-unlock

在分布式团队中，如果 Terraform 进程意外中断，可能留下孤儿锁导致后续操作被阻塞。此时可以手动释放锁：

```shell
terraform force-unlock LOCK_ID
```

::: warning
只在确认没有其他 Terraform 进程正在运行时才使用此命令，否则可能导致状态文件损坏。
:::

## terraform login / logout

用于向 Terraform Cloud / Terraform Enterprise 或其他私有 Registry 保存认证凭据(这方面的内容不是本教程的方向，仅做简略介绍)：

```shell
# 交互式登录（会打开浏览器完成认证流程）
terraform login

# 登录指定 hostname
terraform login app.terraform.io

# 移除本地存储的凭据
terraform logout
```

---

## 动手实验

在以下实验中，你将在真实终端里练习 `-chdir`、`fmt`、`console`、`get`、`graph` 和 `force-unlock` 命令：

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-basics" />
