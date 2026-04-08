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

## 跨命令通用参数

下面四个参数适用于绝大多数 Terraform 子命令，掌握它们能显著提升调试和自动化效率。

### -no-color：禁用颜色码

正常输出含有 ANSI 颜色转义码，CI 日志或写入文件时会变成乱码。用 -no-color 获得纯文本：

```
terraform init -no-color
```

对比一下两种输出的差异：

```
terraform version
terraform version -no-color
```

（在当前终端里两者看起来一样，但把输出重定向到文件后再 cat，有颜色版会看到 ^[[0m 这样的转义序列）

```
terraform version > /tmp/out.txt && cat /tmp/out.txt
terraform version -no-color > /tmp/out-plain.txt && cat /tmp/out-plain.txt
```

### -json：机器可读输出

切换为 NDJSON 格式输出（每行一个 JSON 对象），适合在脚本中解析：

```
terraform init -json
```

查看 validate 的 JSON 输出（包含结构化错误信息）：

```
terraform validate -json
```

用 grep 过滤只看 message 字段：

```
terraform init -json 2>&1 | grep '"@message"'
```

### -input=false：禁用交互提示

禁止 Terraform 向用户发出任何交互询问——若执行中需要输入则直接报错。CI/CD 中必备：

```
terraform init -input=false
```

既然工作目录已经初始化完毕，这条命令会正常完成（无需输入）。
如果把 .terraform 目录删掉再用 -input=false 重新初始化，provider 配置有问题时会立即报错而非等待输入。

### -lock=false 与 -lock-timeout

- -lock=false：跳过状态文件加锁。仅在本地调试时临时使用，生产环境请勿关闭
- -lock-timeout=\<duration\>：等待锁释放的超时，默认 0s（立即失败）

这两个参数对涉及状态文件的命令（plan、apply、destroy）有效，对 init/version/fmt 无实际影响。尝试在当前目录运行：

```
terraform init -lock=false
```
