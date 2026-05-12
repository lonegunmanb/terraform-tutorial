# 第三步：部分配置 (Partial Configuration)

在前面的步骤中，我们把所有后端参数（包括凭据）直接写在了 main.tf 里。在真实项目中，这样做有安全隐患——凭据会被提交到版本控制系统中。

Terraform 提供了**部分配置**（Partial Configuration）机制：在代码中只声明后端类型和非敏感参数，将敏感或环境相关的参数推迟到 terraform init 阶段再提供。

## 查看当前状态

step3 目录有一份使用本地后端的 Terraform 代码（尚未 apply）。我们将从这里开始演示部分配置。

```
cd /root/workspace/step3
cat main.tf
```

## 方式一：通过配置文件提供参数

先修改 main.tf，添加一个空的 azurerm 后端声明：

```
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    # 只声明后端类型，参数留空
    # 剩余参数通过 -backend-config 在 init 时提供
  }
}

provider "azurerm" {
  features {}

  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}

resource "azurerm_resource_group" "app" {
  name     = "partial-config-rg"
  location = "East US"
  tags = {
    Name      = "Partial Config Demo"
    ManagedBy = "Terraform"
  }
}

output "resource_group" {
  value = azurerm_resource_group.app.name
}
EOF
```

注意 backend "azurerm" 块几乎是空的——只声明了使用 azurerm 后端，没有任何具体参数。

创建一个后端配置文件，包含所有后端参数：

```
cat > backend.azurerm.tfbackend <<'EOF'
resource_group_name  = "tfstate-rg"
storage_account_name = "tfstatelab"
container_name       = "tfstate"
key                  = "partial-demo/terraform.tfstate"

metadata_host                   = "localhost:4567"
resource_provider_registrations = "none"

subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000001"
client_id       = "miniblue"
client_secret   = "miniblue"
EOF
```

推荐的命名约定是 *.backendname.tfbackend，例如 backend.azurerm.tfbackend。

使用 -backend-config 参数初始化：

```
terraform init -backend-config=backend.azurerm.tfbackend
```

初始化成功后，apply 创建资源：

```
terraform apply -auto-approve
```

验证状态已存储到远程：

```
terraform plan
```

输出应显示 No changes。

## 方式二：通过命令行键值对提供参数

除了配置文件，也可以直接在命令行中以键值对形式提供参数。我们把状态从方式一的路径（partial-demo/）迁移到新路径（cli-demo/）来演示：

```
terraform init -migrate-state \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=tfstatelab" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=cli-demo/terraform.tfstate" \
  -backend-config="metadata_host=localhost:4567" \
  -backend-config="resource_provider_registrations=none" \
  -backend-config="subscription_id=00000000-0000-0000-0000-000000000000" \
  -backend-config="tenant_id=00000000-0000-0000-0000-000000000001" \
  -backend-config="client_id=miniblue" \
  -backend-config="client_secret=miniblue"
```

当提示迁移时输入 yes。Terraform 会将状态从 partial-demo/ 迁移到 cli-demo/。

验证迁移成功：

```
terraform plan
```

## 方式三：通过环境变量提供参数

azurerm 后端还支持通过环境变量提供敏感参数，这是 CI/CD 中最常见的做法：

| 后端参数 | 环境变量 |
|---------|---------|
| client_id | `ARM_CLIENT_ID` |
| client_secret | `ARM_CLIENT_SECRET` |
| tenant_id | `ARM_TENANT_ID` |
| subscription_id | `ARM_SUBSCRIPTION_ID` |
| metadata_host | `ARM_METADATA_HOST` |

```
export ARM_CLIENT_ID=miniblue
export ARM_CLIENT_SECRET=miniblue
export ARM_TENANT_ID=00000000-0000-0000-0000-000000000001
export ARM_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
```

之后 init 命令就可以省略对应的 -backend-config，进一步减少命令行长度。

## 对比三种方式

| 方式 | 适用场景 | 安全性 |
|------|---------|--------|
| -backend-config=FILE | CI/CD 流水线，参数固定 | 文件可加密存储 |
| -backend-config="KEY=VALUE" | 临时调试或简单场景 | 命令可能留在 shell 历史中 |
| 环境变量（ARM_*） | CI/CD 中的敏感凭据 | 由 CI 系统的 secret 机制管理 |

在实际项目中，推荐组合使用：非敏感参数写在 *.tfbackend 文件里，敏感凭据通过 ARM_* 环境变量注入；并把 *.tfbackend 加入 .gitignore，避免凭据泄漏到版本控制。

## 关键点

- 部分配置允许将后端参数从代码中分离——代码中只声明 backend "azurerm" {}，参数在 init 时提供
- -backend-config=FILE 适合 CI/CD 场景，不同环境使用不同的配置文件
- -backend-config="KEY=VALUE" 适合临时调试，但不推荐用于敏感信息
- ARM_* 环境变量是注入 Azure 凭据的推荐方式
- *.tfbackend 文件不应提交到版本控制系统
