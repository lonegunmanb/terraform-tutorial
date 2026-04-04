# 第一步：重载文件基础 — 参数覆盖与合并规则

在这一步中，你将针对一个完整的 VPC 基础设施配置，逐步创建和修改重载文件，亲身体验 Terraform 重载文件的各种合并行为。

## 查看原始代码

```bash
cd /root/workspace/step1
cat main.tf
```

这是一个典型的 AWS VPC 基础设施配置，包含以下资源：

- 输入变量：environment（默认 "dev"）、vpc_cidr、instance_type（默认 "t3.micro"）
- 局部值：project、environment、name_prefix、common_tags
- 网络层：VPC、两个公有子网（us-east-1a 和 us-east-1b）、一个私有子网、Internet Gateway
- Regional NAT Gateway：包含两个 availability_zone_address 嵌套块（双可用区），配置了 lifecycle { ignore_changes = [tags] }
- 安全组：包含三个 ingress 嵌套块（HTTP / HTTPS / SSH）和一个 egress 块
- EC2 实例：部署在私有子网中

## 初始化

```bash
terraform init
terraform validate
```

用 terraform console 检查当前变量和局部值：

```bash
echo 'var.environment' | terraform console
echo 'var.instance_type' | terraform console
echo 'local.name_prefix' | terraform console
```

你会看到：environment = "dev"、instance_type = "t3.micro"、name_prefix = "myapp-dev"。

## 实验 1：覆盖变量默认值

创建一个重载文件来修改变量的默认值：

```bash
cat > override.tf <<'EOF'
variable "environment" {
  default = "prod"
}

variable "instance_type" {
  default = "m5.large"
}
EOF
```

验证合并后的配置仍然合法，然后检查新值：

```bash
terraform validate
echo 'var.environment' | terraform console
echo 'var.instance_type' | terraform console
echo 'local.name_prefix' | terraform console
```

environment 变成了 "prod"，instance_type 变成了 "m5.large"，name_prefix 自动变为 "myapp-prod"——因为 name_prefix 引用了 var.environment。

重载文件只覆盖了 default，变量的 type 约束保持不变。

## 实验 2：覆盖 locals

locals 的合并是按命名值逐条执行的。更新重载文件，添加 locals 覆盖：

```bash
cat > override.tf <<'EOF'
variable "environment" {
  default = "prod"
}

variable "instance_type" {
  default = "m5.large"
}

locals {
  project = "real-infra"
}
EOF
```

```bash
terraform validate
echo 'local.project' | terraform console
echo 'local.name_prefix' | terraform console
echo 'local.common_tags' | terraform console
```

project 从 "myapp" 变成了 "real-infra"，name_prefix 随之变为 "real-infra-prod"。common_tags 中的 Project 也自动更新了。

关键点：只有 project 这一个命名值被覆盖，environment 和 name_prefix 的定义保持不变——它们只是引用了被覆盖后的值。

## 实验 3：lifecycle 的按参数合并

main.tf 中 NAT Gateway 配置了 lifecycle { ignore_changes = [tags] }。现在在重载文件中添加 create_before_destroy：

```bash
cat > override.tf <<'EOF'
variable "environment" {
  default = "prod"
}

variable "instance_type" {
  default = "m5.large"
}

locals {
  project = "real-infra"
}

resource "aws_nat_gateway" "main" {
  lifecycle {
    create_before_destroy = true
  }
}
EOF
```

```bash
terraform validate
```

配置合法。合并后 NAT Gateway 的 lifecycle 同时包含 ignore_changes = [tags] 和 create_before_destroy = true——两个参数都保留。这是 lifecycle 的特殊合并行为：按参数逐条合并。

注意重载的 resource 块中没有写 availability_mode、vpc_id、availability_zone_address 等参数，它们在源块中的定义都保持不变。

## 实验 4：嵌套块的整体替换

普通嵌套块（非 lifecycle）的合并行为是整体替换。main.tf 中 NAT Gateway 有两个 availability_zone_address 嵌套块（us-east-1a 和 us-east-1b），安全组有三个 ingress 嵌套块（HTTP / HTTPS / SSH）。

先用重载文件将 NAT Gateway 的双可用区缩减为单可用区：

```bash
cat > nat_override.tf <<'EOF'
resource "aws_nat_gateway" "main" {
  availability_zone_address {
    allocation_ids    = [aws_eip.nat_a.id]
    availability_zone = "us-east-1a"
  }
}
EOF
```

```bash
terraform validate
```

配置合法。但合并后的实际效果是：源块中原本的两个 availability_zone_address 块被全部丢弃，替换为重载块中的一个。NAT Gateway 从双可用区变为单可用区——us-east-1b 的配置消失了。

再试试安全组。创建另一个重载文件，将三个 ingress 规则替换为一个：

```bash
cat > sg_override.tf <<'EOF'
resource "aws_security_group" "web" {
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "App port"
  }
}
EOF
```

```bash
terraform validate
```

配置仍然合法。但源块中的三个 ingress 规则（HTTP/HTTPS/SSH）全部被丢弃，只剩下重载块中定义的 8080 端口规则。egress 块不受影响——因为重载块中没有定义 egress 类型的嵌套块。

这就是嵌套块的合并规则：同类型嵌套块整体替换，而非逐个合并。与 lifecycle（按参数合并）的行为完全不同。

清理演示文件：

```bash
rm -f nat_override.tf sg_override.tf
```

## 实验 5：多个重载文件的叠加

重载文件按文件名字典序依次加载。当前目录中有实验 3 创建的 override.tf。创建第二个重载文件来验证叠加效果：

```bash
cat > z_override.tf <<'EOF'
variable "environment" {
  default = "staging"
}
EOF
```

```bash
echo 'var.environment' | terraform console
echo 'local.name_prefix' | terraform console
```

environment 变成了 "staging"，name_prefix 变为 "real-infra-staging"。override.tf 先加载，将 environment 覆盖为 "prod"；z_override.tf 按字典序在其后加载，再次覆盖为 "staging"——后者生效。而 override.tf 中的其他覆盖（instance_type、project、lifecycle）不受影响。

## 清理

```bash
rm -f override.tf z_override.tf
```

## 关键点

- 后缀为 _override.tf 或名为 override.tf 的文件被 Terraform 特殊处理
- 重载文件按文件名字典序加载，效果叠加
- 参数被逐条覆盖，未提及的参数保持不变
- lifecycle 块按参数合并，其他嵌套块整体替换
- locals 按命名值逐条合并
- 不允许在重载块中定义 depends_on

完成后继续下一步。
