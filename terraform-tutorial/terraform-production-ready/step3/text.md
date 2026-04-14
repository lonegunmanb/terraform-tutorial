# 第三步：引入社区模块——terraform-aws-modules

## 为什么要使用社区模块

自制 `modules/storage` 能运行，但它有一些局限：
- 没有处理 S3 的加密配置
- 没有生命周期策略
- 没有日志记录
- 没有跨区域复制配置

`terraform-aws-modules/s3-bucket` 是社区维护的高质量模块，内置了这些生产级特性，并经过大量真实项目的验证。

## 看看更新后的 storage 模块

```bash
cd /root/workspace/step3
cat modules/storage/main.tf
```

与 step2 的版本对比：

```bash
diff /root/workspace/step2/modules/storage/main.tf modules/storage/main.tf
diff /root/workspace/step2/modules/storage/outputs.tf modules/storage/outputs.tf
```

新版本的核心变化：
- 自己创建的 `aws_s3_bucket` 资源被 `module "s3_bucket"` 调用替代
- outputs 使用社区模块的输出属性（`s3_bucket_id`、`s3_bucket_arn`）
- `variables.tf` 接口完全不变——调用方（根模块）不需要做任何修改

**这正是"用自己的模块包裹社区模块"的价值**：内部实现切换，外部接口稳定。

## 初始化并下载社区模块

```bash
terraform init
```

观察输出，Terraform 正在从 Terraform Registry 下载 `terraform-aws-modules/s3-bucket`：

```
Downloading registry.terraform.io/terraform-aws-modules/s3-bucket/aws 4.x.x ...
```

社区模块和本地模块、provider 一起在 `terraform init` 阶段完成下载。

## 部署并验证

```bash
terraform plan
```

`plan` 的输出会显示 `module.storage.module.s3_bucket.*` 这样的嵌套模块资源地址——这是模块嵌套调用的正常表现。

```bash
terraform apply -auto-approve
```

```bash
# 验证 S3 存储桶已创建
awslocal s3 ls
awslocal s3api get-bucket-versioning --bucket config-center-dev-config
```

## 关于版本选择的思考

查看当前使用的版本：

```bash
cat modules/storage/main.tf | grep version
```

`~> 4.2` 的含义是 `>= 4.2, < 5.0`——允许 4.x 系列的任何 patch 升级，但不会突然拉进 5.0 的 breaking change。

**版本选择策略**：
- 生产模块：精确到 `x.y.z`，配合 CI 检测上游更新
- 实验/学习：`~> x.y`，获取 bug fix 但保持接口稳定

## 查看模块的完整输出

```bash
terraform output
```

输出与 step2 完全相同——`modules/storage` 的外部接口没有变化，根模块不需要修改一行代码。

下一步，我们在模块里加入内置防护机制——让错误在部署前就被发现。
