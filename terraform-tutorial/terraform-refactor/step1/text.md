# import — 纳入已有资源

在实际工作中，很多基础设施是在 Terraform 之外创建的——通过控制台、CLI 或其他工具。本节将练习使用 import 块将这些已有资源纳入 Terraform 管理。

## 场景

环境初始化时已经通过 awslocal 命令手动创建了两个 S3 桶。先确认它们的存在：

```
cd /root/workspace/step1
awslocal s3 ls
```

你应该能看到 legacy-app-data 和 legacy-app-logs 两个桶。这些桶不在任何 Terraform 状态文件中——Terraform 并不知道它们的存在。

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

> 提示：import 块只能写在根模块中。如果需要导入到子模块中的资源，可以在 to 地址中使用 module.xxx.resource_type.name 的形式。
