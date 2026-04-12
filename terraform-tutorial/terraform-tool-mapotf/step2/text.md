# 第二步：用 mapotf 消除漂移

## 验证 mapotf 已安装

```
mapotf version
```

## 编写 mapotf 规则

创建规则目录和规则文件：

```
mkdir -p mptf-rules
```

```
cat > mptf-rules/ignore_vpc_tags.mptf.hcl <<'EOF'
# 匹配所有 aws_vpc 类型的资源（包括模块内部的）
data "resource" "vpc" {
  resource_type = "aws_vpc"
}

# 为每个 aws_vpc 资源添加 ignore_changes = [tags, tags_all]
transform "update_in_place" "ignore_vpc_tags" {
  for_each             = try(data.resource.vpc.result.aws_vpc, {})
  target_block_address = each.value.mptf.block_address

  asstring {
    lifecycle {
      ignore_changes = "[tags, tags_all]"
    }
  }
}
EOF
```

这段规则做了两件事：

1. data "resource" "vpc" 匹配所有类型为 aws_vpc 的资源块——包括模块内部的
2. transform "update_in_place" 遍历匹配到的资源，为每个资源插入 lifecycle { ignore_changes = [tags, tags_all] }

## 预览转换效果

先用 transform 模式查看 mapotf 会如何修改文件。注意 -r 参数——它让 mapotf 递归扫描子目录（包括 .terraform/modules/），这样才能修改第三方模块内部的代码：

```
mapotf transform -r --mptf-dir ./mptf-rules --tf-dir .
```

查看模块内部的 aws_vpc 资源被修改了什么：

```
diff .terraform/modules/vpc/main.tf .terraform/modules/vpc/main.tf.mptfbackup
```

你会看到 mapotf 在 aws_vpc 资源块中插入了 lifecycle { ignore_changes = [tags, tags_all] }。

## 验证漂移已消除

现在运行 terraform plan，此时模块代码已被 mapotf 修改：

```
terraform plan
```

标签相关的 drift 应该消失了——Terraform 不再试图移除 compliance-team 和 auto-tagged-at 标签。

你可能仍然看到一个关于 aws_default_network_acl 的 change（egress/ingress 规则差异），这是 LocalStack 对 IPv6 CIDR 模拟不准确导致的，与标签无关，不影响本实验的结论。

## 还原模块代码

确认效果后，还原被修改的文件：

```
mapotf reset -r --tf-dir .
```

验证模块代码已恢复原状：

```
diff .terraform/modules/vpc/main.tf .terraform/modules/vpc/main.tf.mptfbackup 2>/dev/null || echo "已还原（无备份文件）"
```

## 使用 mapotf apply 一步到位

在实际 CI/CD 中，推荐使用 mapotf apply——它会自动完成"转换 → terraform apply → 还原"的完整流程：

```
mapotf apply -r --mptf-dir ./mptf-rules --tf-dir . -auto-approve
```

-r 让转换递归到模块目录，-auto-approve 透传给 terraform apply。mapotf apply 结束后，模块代码自动恢复原状，但 Terraform 状态已经更新。

清理备份文件：

```
mapotf clean-backup -r --tf-dir .
```

## 再次验证

运行 plan 确认一切正常：

```
terraform plan
```

等待几秒让自动标签再次生效，再次 plan：

```
sleep 10
terraform plan
```

如果仍然看到标签 drift，说明 mapotf reset 已还原了模块代码——下次 plan 需要再次通过 mapotf 执行。这就是 mapotf apply 模式的设计：每次执行都是临时修改，不污染模块源码。

## 扩展：同时匹配多种资源

如果合规策略不仅给 VPC 打标签，还给子网、路由表等所有 EC2 资源打标签，可以编写更通用的规则：

```
cat > mptf-rules/ignore_all_ec2_tags.mptf.hcl <<'EOF'
data "resource" "vpc" {
  resource_type = "aws_vpc"
}

data "resource" "subnet" {
  resource_type = "aws_subnet"
}

data "resource" "route_table" {
  resource_type = "aws_route_table"
}

locals {
  all_resources = merge(
    try(data.resource.vpc.result.aws_vpc, {}),
    try(data.resource.subnet.result.aws_subnet, {}),
    try(data.resource.route_table.result.aws_route_table, {}),
  )
}

transform "update_in_place" "ignore_all_tags" {
  for_each             = local.all_resources
  target_block_address = each.value.mptf.block_address

  asstring {
    lifecycle {
      ignore_changes = "[tags, tags_all]"
    }
  }
}
EOF
```

这样一套规则就能覆盖 VPC 模块中所有受标签漂移影响的资源类型。
