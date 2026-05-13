# 用于 Step 2：for_each 导入
variable "rg_envs" {
  type    = set(string)
  default = ["dev", "staging"]
}

resource "azurerm_resource_group" "per_env" {
  for_each = var.rg_envs
  name     = "app-${each.key}-rg"
  location = "East US"
  tags = {
    Environment = each.key
    ManagedBy   = "Terraform"
  }
}
