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

模拟气隙环境——在新目录中使用镜像安装 provider，不访问 registry：

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

注意 init 输出中 provider 来源的提示。从 registry 安装时显示：

```
- Installing hashicorp/aws v5.x.x...
```

从本地镜像安装时显示：

```
- Installing hashicorp/aws v5.x.x, from the shared cache directory...
```

"from the shared cache directory" 或 "from the local mirror" 字样表明 provider 来自本地镜像而非远端 registry。如果你看到这条信息，说明 filesystem_mirror 配置生效了。

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

- 气隙/隔离网络环境：先在有网络的机器上 mirror，再将目录拷贝到隔离环境
- CI 缓存加速：在 CI 中预先 mirror 到共享存储，避免每次 init 都从 registry 下载
- 版本合规审计：mirror 目录作为唯一的 provider 来源，确保所有人使用已审批的版本

回到主工作目录：

```
cd /root/workspace
```

确认理解后进入完成页。
