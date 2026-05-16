# 第三步：提取数据层和存储层

## 查看新增模块

```bash
find /root/stage/step3/modules -name "*.tf" | sort
```

data 和 storage 两个模块分别封装了 Cosmos DB 表和 Storage Account。

```bash
cat /root/stage/step3/modules/data/main.tf
```

```bash
cat /root/stage/step3/modules/storage/main.tf
```

注意 storage 模块中的命名处理——Azure Storage Account 名称必须是 3-24 个字符的纯小写字母数字，所以我们用 replace 和 substr 函数去掉连字符并截断长度。

## 查看新增的 moved 块

```bash
diff /root/workspace/moved.tf /root/stage/step3/moved.tf
```

新增了若干 moved 块，将 Cosmos DB 和 Storage Account 从根模块搬进对应的模块。注意存储层的资源改名：

```
from = azurerm_storage_account.static
to   = module.storage.azurerm_storage_account.static
```

moved 块不仅能搬进模块，还能同时改名。原来叫 static，模块里也叫 static——底层资源不变，地址更清晰。

## 应用重构

```bash
cp -r /root/stage/step3/modules/* /root/workspace/modules/
cp /root/stage/step3/main.tf /root/workspace/
cp /root/stage/step3/moved.tf /root/workspace/
terraform init
```

## 验证零变更

```bash
terraform plan
```

再次：0 to add, 0 to change, 0 to destroy。资源地址更新，没有任何基础设施变更。

```bash
terraform apply -auto-approve -parallelism=2
```

## 查看进度

```bash
terraform state list
```

现在 Cosmos DB 和 Storage Account 也有了 module 前缀：

```
module.data.azurerm_cosmosdb_account.users
module.data.azurerm_cosmosdb_table.users
module.storage.azurerm_storage_account.static
module.storage.azurerm_storage_account.backups
```

```bash
wc -l main.tf
```

main.tf 又缩小了——数据层和存储层的代码被 module 调用替代。只剩安全与身份相关的资源还在根模块。

下一步，提取最后的安全层，并为关键模块加上内置防护。
