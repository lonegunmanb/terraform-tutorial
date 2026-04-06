# 第一步：Provider 的声明

## 场景：从网上复制来的代码

假设你从一篇博客文章中复制了一段使用 Yandex Cloud Provider 的 Terraform 代码。让我们看看它长什么样：

```bash
cd /root/workspace/step1
cat main.tf
```

这段代码直接使用了 yandex Provider 来创建虚拟机，但**没有声明 required_providers**。

## 尝试初始化

```bash
terraform init
```

你会看到类似这样的**错误信息**：

```
Initializing provider plugins...
- Finding latest version of hashicorp/yandex...

Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider
hashicorp/yandex: provider registry registry.terraform.io does not
have a provider named registry.terraform.io/hashicorp/yandex

Did you intend to use yandex-cloud/yandex? If so, you must specify
that source address in each module which requires that provider.
```

为什么会失败？因为：

1. Terraform 看到代码中使用了 yandex 开头的资源
2. 没有 required_providers 声明，Terraform 只能猜测 Provider 的源地址
3. Terraform 默认去 hashicorp 命名空间查找，即 hashicorp/yandex
4. 但 Yandex Cloud Provider 的真实源地址是 yandex-cloud/yandex，不在 hashicorp 命名空间下
5. hashicorp/yandex 不存在，初始化失败

注意 Terraform 甚至贴心地提示了："Did you intend to use yandex-cloud/yandex?"——它猜到了你可能要用的 Provider，但你必须在 required_providers 中显式声明。

这就是 required_providers 存在的核心原因：**告诉 Terraform 去哪里找 Provider**。

## 对比：正确声明的代码

现在看看正确声明了 required_providers 的代码：

```bash
cd /root/workspace/step1/working
cat main.tf
```

注意关键区别——多了一个 terraform 块：

```hcl
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
```

这里明确告诉 Terraform 三件事：
- Provider 的本地名称是 null
- 去 hashicorp/null 这个源地址下载
- 使用 3.x 版本

## 初始化正确的代码

```bash
terraform init
```

这次初始化成功了！你会看到：

```
Initializing provider plugins...
- Finding hashicorp/null versions matching "~> 3.0"...
- Installing hashicorp/null v3.x.x...
- Installed hashicorp/null v3.x.x

Terraform has been successfully initialized!
```

运行 plan 验证一下：

```bash
terraform plan
```

一切正常。

## 查看锁定文件

初始化成功后，Terraform 生成了 .terraform.lock.hcl 文件：

```bash
cat .terraform.lock.hcl
```

这个文件记录了实际安装的 Provider 版本和校验和，确保团队成员使用完全相同的版本。

## 小结

- Terraform 根据资源类型名的第一个单词（下划线前）推断 Provider 本地名称
- 没有 required_providers 时，Terraform 默认去 hashicorp 命名空间查找
- 对于非 hashicorp 命名空间的 Provider（如 aliyun/alicloud），必须在 required_providers 中显式声明 source
- 即使是 hashicorp 命名空间的 Provider，也推荐声明 required_providers 以锁定版本

> 记住：每次复制 Terraform 代码时，不仅要复制 resource 和 provider 块，还要确保 terraform 块中的 required_providers 声明完整。

✅ 你已经理解了 required_providers 声明的必要性。
