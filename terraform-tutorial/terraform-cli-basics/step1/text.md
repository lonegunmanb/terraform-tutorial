# 第一步：terraform version、自动补全与 -chdir

## 查看版本信息

进入工作目录并查看已安装的 Terraform 版本：

```bash
cd /root/workspace
terraform version
```

输出中除了版本号，还会显示当前操作系统和 CPU 架构信息。如果有新版本可用，也会提示。

## 查看帮助文档

不带参数运行 terraform 可查看所有子命令列表：

```bash
terraform
```

使用 -help 查看具体子命令用法，例如获取 fmt 的帮助：

```bash
terraform fmt -help
```

仔细阅读输出，找到 -check、-diff、-recursive 几个参数的说明。

## 自动补全

安装命令行自动补全（支持 bash 和 zsh）：

```bash
terraform -install-autocomplete
```

安装完成后重开一个新 shell，输入 terraform 开头再按 Tab 键就会出现子命令的候选列表。

如需卸载：

```bash
terraform -uninstall-autocomplete
```

## 使用 -chdir 不切目录运行命令

首先在 /root 目录创建一个测试子目录：

```bash
mkdir -p /root/alt-dir
ls /root/workspace/
```

现在不进入 /root/workspace 就对它执行 terraform version：

```bash
cd /root
terraform -chdir=/root/workspace version
```

接着在导诺处于 /root 的情况下，用 -chdir 查看 workspace 中的文件列表：

```bash
terraform -chdir=/root/workspace fmt -check
```

这就是 -chdir 的典型用法——在脚本或 CI 流水线中，无需改变当前目录就能对任意路径的 Terraform 配置执行命令。

回到工作目录：

```bash
cd /root/workspace
```
