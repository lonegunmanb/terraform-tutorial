# ==============================
# Terraform 类型示例：集合类型
# ==============================

# ── list 类型 ──
# list 是有序集合，元素类型相同，下标从 0 开始
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ports" {
  type    = list(number)
  default = [80, 443, 8080]
}

# ── map 类型 ──
# map 是键值对集合，键一定是 string，值类型相同
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
    Project     = "demo"
  }
}

variable "instance_counts" {
  type = map(number)
  default = {
    web = 3
    api = 2
    db  = 1
  }
}

# ── set 类型 ──
# set 是无序、不重复的集合
variable "allowed_cidrs" {
  type    = set(string)
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

locals {
  # list 用下标访问
  first_zone = var.availability_zones[0]
  # => "us-east-1a"

  # list 长度
  zone_count = length(var.availability_zones)
  # => 3

  # map 用键名访问
  env_tag = var.tags["Environment"]
  # => "dev"

  # map 获取所有键
  tag_keys = keys(var.tags)

  # set 不能用下标访问，但可以用 contains 检查元素
  has_private = contains(var.allowed_cidrs, "10.0.0.0/8")
  # => true

  # list(any) 隐式类型转换：所有元素会被转为同一类型
  mixed_to_string = tolist(["hello", 42, true])
  # => ["hello", "42", "true"]（全部转换为 string）

  # ⚠️ "同一类型"比你想象的更严格！
  # 以下写法看起来像合法的 list 或 map，但会报错：
  #
  #   tolist(["hello", ["a", "b"]])
  #   # ❌ 报错！string 和 list 无法转换为同一类型
  #
  #   tomap({name = "alice", config = { port = 8080 }})
  #   # ❌ 报错！string 和 object 不是同一类型
  #
  # 经验法则：如果不同键需要不同类型的值，用 object 而不是 map
}

output "first_zone" {
  value = local.first_zone
}

output "zone_count" {
  value = local.zone_count
}

output "env_tag" {
  value = local.env_tag
}

output "tag_keys" {
  value = local.tag_keys
}

output "has_private" {
  value = local.has_private
}

output "mixed_to_string" {
  value = local.mixed_to_string
}

output "ports" {
  value = var.ports
}

output "instance_counts" {
  value = var.instance_counts
}
