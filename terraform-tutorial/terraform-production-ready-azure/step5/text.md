# 第五步：状态隔离——Terragrunt + removed 块

## 查看拆分后的目录

```bash
find /root/stage/step5 -name "*.tf" -o -name "*.hcl" | sort
```

每个层级目录只保留自己的 module 调用，并通过 removed 块把其它模块从当前 state 释放出去，但不销毁远端资源。

```bash
cat /root/stage/step5/networking/removed.tf
cat /root/stage/step5/web/terragrunt.hcl
```

## 应用状态拆分

```bash
cp -r /root/stage/step5/* /root/workspace/
for layer in networking security web storage dns; do
  cp /root/workspace/terraform.tfstate /root/workspace/$layer/
done
rm /root/workspace/main.tf /root/workspace/moved.tf
```

初始化并应用所有层：

```bash
cd /root/workspace
terragrunt run-all init --terragrunt-non-interactive
terragrunt run-all apply -auto-approve --terragrunt-non-interactive
```

## 验证每层独立 state

```bash
for layer in networking security web storage dns; do
  echo "=== $layer ==="
  (cd /root/workspace/$layer && terraform state list)
done
```

现在网络、安全、虚拟机、存储、DNS 各自拥有独立状态。修改单层时，Terraform 不需要刷新整套基础设施。
