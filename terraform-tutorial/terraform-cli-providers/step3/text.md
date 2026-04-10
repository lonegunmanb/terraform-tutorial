# 第三步：providers mirror 离线镜像

## 创建本地镜像

将当前配置需要的所有 provider 下载到本地镜像目录：

```
cd /root/workspace
mkdir -p /root/mirror
terraform providers mirror /root/mirror
```

Terraform 下载 aws 和 random 两个 provider 的包到镜像目录。

## 查看镜像目录结构

```
find /root/mirror -type f | head -20
```

目录按 registry.terraform.io/hashicorp/PROVIDER/VERSION/PLATFORM/ 结构组织，包含 .zip 文件和 .json 索引文件。

查看某个 provider 的版本信息：

```
ls /root/mirror/registry.terraform.io/hashicorp/aws/
```

## 使用镜像目录进行离线安装

模拟无互联网的隔离环境——在新目录中使用镜像安装 provider，不访问 registry：

```
mkdir -p /root/offline-demo
cd /root/offline-demo
cp /root/workspace/main.tf .
```

创建 CLI 配置文件，指定使用本地镜像：

```
cat > ~/.terraformrc <<'EOF'
provider_installation {
  filesystem_mirror {
    path = "/root/mirror"
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF
```

运行 init，Terraform 从本地镜像安装 provider 而非从 registry 下载：

```
terraform init
```

注意 init 输出中 provider 来源的关键线索：

- 从 registry 安装时显示 `(signed by HashiCorp)`——表示包经过了 HashiCorp 的签名验证
- 从本地镜像安装时显示 `(unauthenticated)`——表示包未经签名验证，来自本地文件系统

看到 `(unauthenticated)` 说明 filesystem_mirror 配置生效了。Terraform 还会输出一条 Warning: Incomplete lock file information，提示你锁文件中只包含当前平台的校验和——这也是因为使用了自定义安装方式（customized provider installation methods）。

验证安装成功：

```
terraform providers
```

清理 CLI 配置（恢复默认行为）：

```
rm -f ~/.terraformrc
```

## mirror 的实际场景

providers mirror 在以下场景中特别有价值：

- 无互联网的隔离网络环境（air-gapped）：先在有网络的机器上 mirror，再将目录拷贝到隔离环境
- CI 缓存加速：在 CI 中预先 mirror 到共享存储，避免每次 init 都从 registry 下载
- 版本合规审计：mirror 目录作为唯一的 provider 来源，确保所有人使用已审批的版本

回到主工作目录：

```
cd /root/workspace
```

确认理解后进入完成页。
