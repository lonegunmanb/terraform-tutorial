# 第二步：providers lock 跨平台锁定

## 查看当前锁文件

查看当前锁文件中记录了哪些平台的校验和：

```
cd /root/workspace
grep -A 2 "h1:" .terraform.lock.hcl | head -20
```

当前锁文件只包含本机平台（linux_amd64）的校验和。

## 为多平台生成校验和

假设团队中有人使用 macOS，有人使用 Linux。用 providers lock 为两个平台生成校验和：

```
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_amd64
```

Terraform 会从 registry 获取这两个平台的包校验和，并写入锁文件。

查看更新后的锁文件：

```
grep "h1:" .terraform.lock.hcl
```

现在每个 provider 下有更多的哈希条目，覆盖了两个平台。

## 用新配置演示 lock

切换到一个新目录，使用预置的配置文件（包含 aws 和 null 两个 provider）：

```
mkdir -p /root/lock-demo
cd /root/lock-demo
cp /root/lock-demo.tf main.tf
```

此时还没有锁文件。直接运行 providers lock：

```
terraform providers lock -platform=linux_amd64
```

查看生成的锁文件：

```
cat .terraform.lock.hcl
```

锁文件中记录了 aws 和 null 两个 provider 的版本和校验和。

注意此时只运行了 providers lock，并没有 init——provider 插件还未安装到本地。确认 .terraform 目录不存在：

```
ls .terraform 2>/dev/null || echo ".terraform 目录不存在"
```

providers lock 只更新锁文件，不安装 provider。要安装 provider 仍需运行 terraform init。

回到主工作目录：

```
cd /root/workspace
```

进入下一步学习 providers mirror。
