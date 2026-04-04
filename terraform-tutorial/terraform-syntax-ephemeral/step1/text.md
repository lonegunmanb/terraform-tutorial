# 第一步：ephemeral vs resource — 状态文件中的差异

在这一步中，你将用同一个 Provider (`random_password`) 分别以 `resource` 和 `ephemeral` 两种方式生成密码，然后对比它们在状态文件中的表现。

## 查看代码

```bash
cd /root/workspace/step1
cat main.tf
```

观察代码中的两种方式：

- **resource "random_password"** — 普通资源，密码会保存到状态文件
- **ephemeral "random_password"** — 临时资源，密码不会保存到状态文件
- ephemeral 的值可以通过 `local` 中转，但不能作为根模块的 output 输出

## 执行 Apply

```bash
terraform apply -auto-approve
```

注意输出中 resource_password 显示为 `(sensitive value)` — 值被隐藏但仍然存在于状态文件中。

## 检查状态文件

这是本实验最关键的环节。查看状态文件中保存了什么：

```bash
terraform state list
```

你会发现只有一个资源：`random_password.resource_password`。临时资源 `ephemeral.random_password.ephemeral_password` 完全不在状态列表中。

现在查看普通资源在状态文件中的详细信息：

```bash
terraform state show random_password.resource_password
```

你会看到 result 和 bcrypt_hash 显示为 (sensitive value)——命令行隐藏了它们。但这只是显示层面的保护，数据实际上明文存储在状态文件中。

直接查看状态文件的 JSON 内容，搜索密码：

```bash
cat terraform.tfstate | python3 -m json.tool | grep -A2 '"result"'
```

密码就在这里——任何能访问状态文件的人都能读取它。

现在试试查看临时资源：

```bash
terraform state show ephemeral.random_password.ephemeral_password 2>&1 || true
```

Terraform 会报错，因为临时资源根本不存在于状态文件中。在 JSON 中搜索也找不到：

```bash
cat terraform.tfstate | grep "ephemeral" || echo "状态文件中没有 ephemeral 的任何痕迹"
```

## 再次 Apply 观察差异

```bash
terraform apply -auto-approve
```

注意观察：
- random_password.resource_password 显示 **no changes** — 因为状态文件中已经有了，不需要重新生成
- 而临时资源每次运行都会重新生成（因为没有状态记录），但你在输出中看不到它的值（根模块不允许临时输出）

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- resource 生成的密码保存在状态文件中，任何能读取状态的人都能看到
- ephemeral 生成的密码不保存到状态文件，每次运行都重新生成
- ephemeral 的值只能在临时上下文中引用（local、provider、provisioner 等），不能作为根模块的 output
- sensitive = true 只是隐藏命令行输出，数据仍在状态文件中；ephemeral 则彻底不持久化

完成后继续下一步。
