# state mv：移动/重命名资源

当你在配置中重命名资源或将资源移入模块时，Terraform 会认为旧名称的资源要删除、新名称的资源要创建。state mv 可以避免不必要的销毁重建。

## 1. 观察问题

当前配置中 S3 桶名为 aws_s3_bucket.app。假设我们要把它重命名为 aws_s3_bucket.application。

先看一下当前状态：

```
cd /root/workspace
terraform state list
```

如果直接修改配置文件中的资源名称而不调整状态，Terraform 会计划删除旧资源并创建新资源。

## 2. -dry-run 预览

在执行前先用 -dry-run 确认变更：

```
terraform state mv -dry-run aws_s3_bucket.app aws_s3_bucket.application
```

输出类似：

```
Would move "aws_s3_bucket.app" to "aws_s3_bucket.application"
```

确认无误后执行。

## 3. 执行 state mv

```
terraform state mv aws_s3_bucket.app aws_s3_bucket.application
```

输出：

```
Move "aws_s3_bucket.app" to "aws_s3_bucket.application"
Successfully moved 1 object(s).
```

验证状态中的资源名称已更新：

```
terraform state list
```

现在应该看到 aws_s3_bucket.application 而不是 aws_s3_bucket.app。

## 4. 同步配置文件

状态已更新，但配置文件还是旧名称。用预备好的配置文件替换：

```
cp /root/main-step2.tf /root/workspace/main.tf
```

在编辑器中查看 main.tf，确认资源名称已改为 application。

运行 plan 验证：

```
terraform plan
```

应该看到 No changes，说明配置和状态已经一致，资源没有被销毁重建。

## 5. 查看自动备份

state mv 会自动创建备份文件：

```
ls -la *.backup
```

如果操作出错，可以用备份恢复：

```
# 仅供了解，不要实际执行
# cp terraform.tfstate.backup terraform.tfstate
```
