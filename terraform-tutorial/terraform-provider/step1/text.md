# 第一步：Provider 的声明

## 场景：从网上复制来的代码

假设你从一篇博客文章中复制了一段使用 Azure API Provider（azapi）的 Terraform 代码。让我们看看它长什么样：

```bash
cd /root/workspace/step1
cat main.tf
```

这段代码直接使用了 azapi Provider 来创建 Azure 资源，但**没有声明 required_providers**。

## 尝试初始化

```bash
terraform init
```

你会看到类似这样的**错误信息**：

```
Initializing provider plugins...
- Finding latest version of hashicorp/azapi...

Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider
hashicorp/azapi: provider registry registry.terraform.io does not
have a provider named registry.terraform.io/hashicorp/azapi
```

为什么会失败？因为：

1. Terraform 看到代码中使用了 azapi 开头的资源
2. 没有 required_providers 声明，Terraform 只能猜测 Provider 的源地址
3. Terraform 默认去 hashicorp 命名空间查找，即 hashicorp/azapi
4. 但 Azure API Provider 的真实源地址是 Azure/azapi，不在 hashicorp 命名空间下
5. hashicorp/azapi 不存在，初始化失败

这就是 required_providers 存在的核心原因：**告诉 Terraform 去哪里找 Provider**。

## 修复：添加 required_providers

现在让我们来修复这段代码。用编辑器（左侧面板）打开 /root/workspace/step1/main.tf，在文件**最前面**添加一个 terraform 块：

```hcl
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}
```

你也可以用命令快速插入：

```bash
sed -i '1i terraform {\n  required_providers {\n    azapi = {\n      source  = "Azure/azapi"\n      version = "~> 2.0"\n    }\n  }\n}\n' main.tf
```

这个 terraform 块明确告诉 Terraform 三件事：
- Provider 的本地名称是 azapi
- 去 Azure/azapi 这个源地址下载
- 使用 2.x 版本

## 重新初始化

```bash
terraform init
```

这次初始化成功了！你会看到：

```
Initializing provider plugins...
- Finding Azure/azapi versions matching "~> 2.0"...
- Installing Azure/azapi v2.x.x...
- Installed Azure/azapi v2.x.x

Terraform has been successfully initialized!
```

## 查看锁定文件

初始化成功后，Terraform 生成了 .terraform.lock.hcl 文件：

```bash
cat .terraform.lock.hcl
```

这个文件记录了实际安装的 Provider 版本和校验和，确保团队成员使用完全相同的版本。

## 小结

- Terraform 根据资源类型名的第一个单词（下划线前）推断 Provider 本地名称
- 没有 required_providers 时，Terraform 默认去 hashicorp 命名空间查找
- 对于非 hashicorp 命名空间的 Provider（如 Azure/azapi），必须在 required_providers 中显式声明 source
- 即使是 hashicorp 命名空间的 Provider，也推荐声明 required_providers 以锁定版本

> 记住：每次复制 Terraform 代码时，不仅要复制 resource 和 provider 块，还要确保 terraform 块中的 required_providers 声明完整。

✅ 你已经理解了 required_providers 声明的必要性，并亲手修复了一段缺少声明的代码。
