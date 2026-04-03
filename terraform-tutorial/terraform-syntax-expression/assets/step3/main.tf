# ==============================
# Terraform 表达式示例：for 表达式与 splat
# ==============================

variable "names" {
  type    = list(string)
  default = ["alice", "bob", "charlie", ""]
}

variable "servers" {
  type = list(object({
    name = string
    port = number
  }))
  default = [
    { name = "web",  port = 80 },
    { name = "api",  port = 8080 },
    { name = "db",   port = 5432 },
  ]
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
    Project     = "demo"
  }
}

# ── for 表达式：输出元组 ──
locals {
  # 将所有名字转为大写
  upper_names = [for s in var.names : upper(s)]
  # => ["ALICE", "BOB", "CHARLIE", ""]
}

output "for_tuple" {
  value = local.upper_names
}

# ── for 表达式：带 if 过滤 ──
locals {
  # 过滤掉空字符串
  valid_names = [for s in var.names : upper(s) if s != ""]
  # => ["ALICE", "BOB", "CHARLIE"]
}

output "for_filtered" {
  value = local.valid_names
}

# ── for 表达式：输出对象 ──
locals {
  # 构建 name => uppercase_name 的映射
  name_map = { for s in var.names : s => upper(s) if s != "" }
  # => { "alice" = "ALICE", "bob" = "BOB", "charlie" = "CHARLIE" }
}

output "for_object" {
  value = local.name_map
}

# ── for 表达式：遍历 map ──
locals {
  # 遍历 map，将键值对拼成 "key=value" 列表
  tag_strings = [for k, v in var.tags : "${k}=${v}"]
  # => ["Environment=dev", "Project=demo", "Team=platform"]
}

output "for_map" {
  value = local.tag_strings
}

# ── for 表达式：分组 (group by) ──
locals {
  fruits = ["apple", "avocado", "banana", "blueberry", "cherry"]

  # 按首字母分组，使用 ... 聚合同键的值为列表
  grouped = { for s in local.fruits : substr(s, 0, 1) => s... }
  # => { "a" = ["apple", "avocado"], "b" = ["banana", "blueberry"], "c" = ["cherry"] }
}

output "for_grouped" {
  value = local.grouped
}

# ── splat 表达式 ──
locals {
  # 等价于 [for s in var.servers : s.name]
  server_names = var.servers[*].name
  # => ["web", "api", "db"]

  # 等价于 [for s in var.servers : s.port]
  server_ports = var.servers[*].port
  # => [80, 8080, 5432]
}

output "splat" {
  value = {
    names = local.server_names
    ports = local.server_ports
  }
}

# ── 综合示例：for + 条件 + 函数 ──
locals {
  # 找出端口号大于 1000 的服务器，生成 "NAME:PORT" 格式
  high_port_servers = [
    for s in var.servers : "${upper(s.name)}:${s.port}"
    if s.port > 1000
  ]
  # => ["API:8080", "DB:5432"]
}

output "combined" {
  value = local.high_port_servers
}

# ── 新旧 splat 语法对比 ──
variable "nodes" {
  type = list(object({
    name       = string
    interfaces = list(object({ ip = string }))
  }))
  default = [
    { name = "web", interfaces = [{ ip = "10.0.0.1" }, { ip = "10.0.0.2" }] },
    { name = "api", interfaces = [{ ip = "10.0.1.1" }, { ip = "10.0.1.2" }] },
  ]
}

locals {
  # 新语法 [*]：对每个元素完整求值 interfaces[0].ip
  first_ips_new = var.nodes[*].interfaces[0].ip
  # => ["10.0.0.1", "10.0.1.1"]  ← 每个 node 的第一个接口 IP

  # 旧语法 .*：[0] 跳出 splat，取的是结果列表的第 0 个元素
  first_node_interfaces = var.nodes.*.interfaces[0]
  # => [{ ip = "10.0.0.1" }, { ip = "10.0.0.2" }]  ← 第一个 node 的所有接口
}

output "splat_new_vs_legacy" {
  value = {
    new_syntax    = local.first_ips_new
    legacy_syntax = local.first_node_interfaces
  }
}
