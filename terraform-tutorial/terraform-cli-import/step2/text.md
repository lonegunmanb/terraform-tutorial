# 第二步：导入到 for_each 资源

## 查看预置的 for_each 配置

/root 下已预置了 foreach.tf 文件，查看其内容：

```
cat /root/foreach.tf
```

配置使用 for_each 为 dev 和 staging 两个环境各创建一个 S3 桶。环境中已通过 awslocal 预创建了 app-dev 和 app-staging 这两个桶。

将配置复制到工作目录：

```
cp /root/foreach.tf .
```

## 尝试不导入直接 plan

先看看如果不导入会怎样：

```
terraform plan
```

plan 显示要创建两个新桶——Terraform 不知道这些桶已经存在。如果直接 apply，会因为桶名冲突而报错。

## 用命令行导入 for_each 资源

for_each 资源的地址需要带上 key：

```
terraform import 'aws_s3_bucket.per_env["dev"]' app-dev
terraform import 'aws_s3_bucket.per_env["staging"]' app-staging
```

注意地址中的引号——使用单引号包裹整个地址，key 用双引号。

确认导入成功：

```
terraform state list
```

可以看到带 key 的资源地址。

## 验证配置对齐

运行 plan 验证：

```
terraform plan
```

如果 plan 显示要修改标签，这是预期的——配置中声明了 tags，但 awslocal 创建桶时可能没有设置。执行 apply 使标签对齐：

```
terraform apply -auto-approve
```

验证标签已设置：

```
awslocal s3api get-bucket-tagging --bucket app-dev
```

最终确认所有资源都在 Terraform 管理中：

```
terraform state list
```

确认列出了所有导入的资源后进入完成页。
