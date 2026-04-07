# import — 纳入已有资源

在实际工作中，很多基础设施是在 Terraform 之外创建的——通过控制台、CLI 或其他工具。本节将练习使用 import 块将这些已有资源纳入 Terraform 管理。

## 场景

环境初始化时已经通过 awslocal 命令手动创建了两个 S3 桶。先确认它们的存在：

```
cd /root/workspace/step1
awslocal s3 ls
```

你会看到很多桶——其中 legacy- 开头的是通过 awslocal 手动创建的，其余的是后续步骤预创建的。我们关注的是 legacy-app-data 和 legacy-app-logs 这两个桶。它们不在当前目录的 Terraform 状态文件中——Terraform 并不知道它们的存在。

## 确认 Terraform 不知道这些桶

查看当前状态：

```
terraform state list
```

输出为空——Terraform 没有管理任何资源。

## 编写 import 块和 resource 块

打开 main.tf，在文件底部添加以下代码来导入第一个桶：

```hcl
import {
  to = aws_s3_bucket.app_data
  id = "legacy-app-data"
}

resource "aws_s3_bucket" "app_data" {
  bucket = "legacy-app-data"
}
```

import 块告诉 Terraform：id 为 legacy-app-data 的 S3 桶应该对应 aws_s3_bucket.app_data 这个资源地址。

## 执行计划

```
terraform plan
```

注意观察输出——你应该看到的是 import 操作，而不是 create：

```
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

这说明 Terraform 不会重新创建这个桶，而是将已有的桶纳入管理。

## 执行导入

```
terraform apply -auto-approve
```

验证桶已进入状态文件：

```
terraform state list
```

现在应该能看到 aws_s3_bucket.app_data。

查看状态中记录的详细信息：

```
terraform state show aws_s3_bucket.app_data
```

## 练习：导入第二个桶

请自行在 main.tf 中添加 import 块和 resource 块来导入 legacy-app-logs。

完成后执行：

```
terraform apply -auto-approve
terraform state list
```

确认两个桶都已被 Terraform 管理。

## 验证：import 块是一次性的

再次执行 plan：

```
terraform plan
```

输出应该是 No changes——import 块对已存在于状态中的资源不会重复执行。

## 使用 for_each 批量导入

两个桶手动写两组 import + resource 还可以接受。但如果有更多桶呢？

环境中还有三个手动创建的服务桶，先确认：

```
awslocal s3 ls | grep legacy-svc
```

你应该看到 legacy-svc-orders、legacy-svc-payments 和 legacy-svc-notifications 三个桶。

用 for_each 可以一次性导入所有同类型的资源。在 main.tf 底部添加：

```hcl
locals {
  service_buckets = {
    orders        = "legacy-svc-orders"
    payments      = "legacy-svc-payments"
    notifications = "legacy-svc-notifications"
  }
}

import {
  for_each = local.service_buckets
  to       = aws_s3_bucket.services[each.key]
  id       = each.value
}

resource "aws_s3_bucket" "services" {
  for_each = local.service_buckets
  bucket   = each.value
}
```

关键点：import 块也支持 for_each——它会遍历 map，为每个元素执行一次导入。to 地址中的 each.key 对应 map 的键（orders、payments、notifications）。

## 执行批量导入

```
terraform plan
```

你应该看到三个 import 操作：

```
Plan: 3 to import, 0 to add, 0 to change, 0 to destroy.
```

执行：

```
terraform apply -auto-approve
```

验证所有五个桶都已纳入管理：

```
terraform state list
```

你应该看到五个资源：两个单独导入的（app_data、app_logs），三个通过 for_each 批量导入的（services["orders"]、services["payments"]、services["notifications"]）。

> 提示：import 块只能写在根模块中。如果需要导入到子模块中的资源，可以在 to 地址中使用 module.xxx.resource_type.name 的形式。
