# CLI 配置文件：插件缓存、Provider 镜像与 Checkpoint 控制

## 默认行为：无配置文件

进入工作目录，先看一下当前没有任何 CLI 配置文件：

```
cd /root/workspace
ls -la ~/.terraformrc 2>/dev/null || echo "~/.terraformrc 不存在"
echo "TF_CLI_CONFIG_FILE=${TF_CLI_CONFIG_FILE:-未设置}"
```

在没有配置文件的情况下执行初始化：

```
terraform init
```

Terraform 从 Registry 直接下载 AWS Provider 插件到 .terraform/providers/ 目录。查看下载的插件：

```
find .terraform/providers -type f -name "terraform-provider-*" | head -5
du -sh .terraform/providers
```

记住这个大小——稍后我们用缓存来避免重复下载。

## 启用插件缓存

创建缓存目录和 CLI 配置文件：

```
mkdir -p ~/.terraform.d/plugin-cache
```

```
cat > ~/.terraformrc <<'EOF'
plugin_cache_dir = "/root/.terraform.d/plugin-cache"
EOF
```

验证配置文件已创建：

```
cat ~/.terraformrc
```

现在删除已下载的插件，重新初始化：

```
rm -rf .terraform .terraform.lock.hcl
terraform init
```

检查缓存目录——Provider 插件已被缓存：

```
find ~/.terraform.d/plugin-cache -type f -name "terraform-provider-*"
```

再看工作目录中的插件——Terraform 创建了指向缓存的符号链接而非完整拷贝：

```
find .terraform/providers -type l
```

现在验证缓存的效果。创建第二个工作目录：

```
mkdir -p /root/workspace2
cp main.tf /root/workspace2/
cd /root/workspace2
terraform init
```

注意初始化速度明显更快——Terraform 直接从缓存复制，不需要再次下载。

查看两个工作目录共享同一份缓存：

```
find ~/.terraform.d/plugin-cache -type f | wc -l
```

回到原工作目录继续实验：

```
cd /root/workspace
```

## 关闭 Checkpoint

Terraform 默认联网检查版本更新。在配置文件中关闭它：

```
cat > ~/.terraformrc <<'EOF'
plugin_cache_dir   = "/root/.terraform.d/plugin-cache"
disable_checkpoint = true
EOF
```

验证配置：

```
cat ~/.terraformrc
```

此后 terraform version 不再联网查询最新版本（在离线或受限网络环境中避免超时）：

```
terraform version
```

你会发现输出中不再提示有新版本可用（如果之前有的话），因为 Checkpoint 已被禁用。

## 使用 TF_CLI_CONFIG_FILE 切换配置

在某些场景下（如 CI/CD 或 Provider 开发），你可能需要使用不同的配置文件。通过环境变量切换：

```
cat > /tmp/no-cache.tfrc <<'EOF'
disable_checkpoint = true
EOF
```

```
TF_CLI_CONFIG_FILE=/tmp/no-cache.tfrc terraform version
```

这只影响当前命令，不改变默认的 ~/.terraformrc。

## Provider filesystem_mirror 本地镜像

在离线或防火墙环境中，可以配置 Terraform 从本地目录安装 Provider。

先把已缓存的 Provider 打包为文件系统镜像：

```
mkdir -p /root/terraform-mirror
cp -r ~/.terraform.d/plugin-cache/registry.terraform.io /root/terraform-mirror/
```

查看镜像目录结构：

```
find /root/terraform-mirror -type f
```

现在创建一个只使用本地镜像（不联网）的配置文件：

```
cat > /tmp/offline.tfrc <<'EOF'
disable_checkpoint = true

provider_installation {
  filesystem_mirror {
    path = "/root/terraform-mirror"
  }
}
EOF
```

验证离线安装——删除已有插件，使用离线配置重新初始化：

```
rm -rf .terraform .terraform.lock.hcl
TF_CLI_CONFIG_FILE=/tmp/offline.tfrc terraform init
```

Terraform 完全从本地镜像安装 Provider，没有任何网络请求。

恢复默认配置：

```
rm -rf .terraform .terraform.lock.hcl
terraform init
```

---

## 练习

请完成以下任务：

1. 编辑 ~/.terraformrc，同时启用 plugin_cache_dir 和 disable_checkpoint
2. 创建一个新的配置文件 /tmp/mixed.tfrc，使用 provider_installation 块配置混合安装策略：hashicorp/aws 从 filesystem_mirror（/root/terraform-mirror）获取，其他 Provider 通过 direct 方式下载
3. 使用 TF_CLI_CONFIG_FILE=/tmp/mixed.tfrc terraform init 初始化，确认成功

提示：需要在 filesystem_mirror 中使用 include，在 direct 中使用 exclude，模式为 "hashicorp/aws"。

完成后，查看参考答案验证：

```
cat <<'ANSWER'
# /tmp/mixed.tfrc 参考答案

disable_checkpoint = true

provider_installation {
  filesystem_mirror {
    path    = "/root/terraform-mirror"
    include = ["hashicorp/aws"]
  }
  direct {
    exclude = ["hashicorp/aws"]
  }
}
ANSWER
```

用以下命令验证：

```
rm -rf .terraform .terraform.lock.hcl
TF_CLI_CONFIG_FILE=/tmp/mixed.tfrc terraform init
```

如果看到 "Terraform has been successfully initialized!" 则说明配置正确。
