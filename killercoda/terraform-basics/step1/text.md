# 第一步：初始化 Terraform

进入工作目录并初始化 Terraform：

```bash
cd /root/workspace
terraform init
```

`terraform init` 做了什么？
- 读取 `main.tf` 中声明的 `required_providers`
- 从 Terraform Registry 下载 `hashicorp/aws` Provider 插件
- 在 `.terraform/` 目录中缓存插件
- 生成 `.terraform.lock.hcl` 锁定文件

✅ 当你看到 **"Terraform has been successfully initialized!"** 就说明初始化成功了。
