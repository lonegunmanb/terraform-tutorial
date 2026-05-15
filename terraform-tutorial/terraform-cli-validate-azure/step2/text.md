# 第二步：常见错误类型

## 必填属性缺失

创建一个新文件，声明一个缺少必填属性的资源：

```
cat > extra.tf <<'EOF'
resource "azurerm_virtual_network" "net" {
  name                = "myapp-dev-vnet-lab"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
EOF
```

azurerm_virtual_network 资源要求必须指定 address_space（或 ip_address_pool）。运行 validate：

```
terraform validate
```

报错指出缺少必填属性：

```
Error: Invalid combination of arguments

  with azurerm_virtual_network.net,
  on extra.tf line 1, in resource "azurerm_virtual_network" "net":
   1: resource "azurerm_virtual_network" "net" {

"address_space": one of `address_space,ip_address_pool` must be specified
```

（同时还会再报一条对称的 `ip_address_pool` 缺失错误——azurerm v4 要求二者必须指定其一。）

修复——补上必填属性：

```
cat > extra.tf <<'EOF'
resource "azurerm_virtual_network" "net" {
  name                = "myapp-dev-vnet-lab"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}
EOF
terraform validate
```

确认通过。

## 引用不存在的资源

修改 extra.tf，引用一个不存在的资源：

```
cat > extra.tf <<'EOF'
resource "azurerm_virtual_network" "net" {
  name                = "myapp-dev-vnet-lab"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["10.0.0.0/16"]
}
EOF
terraform validate
```

报错：

```
Error: Reference to undeclared resource

  on extra.tf line 3, in resource "azurerm_virtual_network" "net":
   3:   location            = azurerm_resource_group.network.location

A managed resource "azurerm_resource_group" "network" has not been declared in the root module.
```

（line 4 的 `resource_group_name` 也会触发同样的错误。）

配置中没有声明过 azurerm_resource_group.network（只有 azurerm_resource_group.main），validate 精确定位了这个引用错误。

清理 extra.tf：

```
rm extra.tf
terraform validate
```

确认 Success 后进入下一步。
