# ==============================
# Terraform 局部值示例
# ==============================

# ── 1. 定义局部值 ──
locals {
  project     = "my-app"
  environment = "dev"
  region      = "us-east-1"
}

# 可以定义多个 locals 块，按逻辑分组
locals {
  # 引用其他局部值
  full_name = "${local.project}-${local.environment}"

  # 使用条件表达式
  is_prod = local.environment == "prod"
}

output "basic" {
  value = {
    project     = local.project
    environment = local.environment
    region      = local.region
    full_name   = local.full_name
    is_prod     = local.is_prod
  }
}

# ── 2. 局部值可以是各种类型 ──
locals {
  # 字符串
  greeting = "Hello, ${local.project}!"

  # 数字
  max_instances = 3

  # 布尔值
  enable_logging = true

  # 列表
  availability_zones = ["${local.region}a", "${local.region}b", "${local.region}c"]

  # Map
  base_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

output "types" {
  value = {
    greeting           = local.greeting
    max_instances      = local.max_instances
    enable_logging     = local.enable_logging
    availability_zones = local.availability_zones
    base_tags          = local.base_tags
  }
}

# ── 3. 避免重复：合并标签 ──
variable "extra_tags" {
  type = map(string)
  default = {
    Owner = "team-platform"
  }
}

locals {
  # merge 将多个 map 合并为一个，定义一次、多处引用
  common_tags = merge(local.base_tags, var.extra_tags)
}

output "common_tags" {
  value = local.common_tags
}

# ── 4. 命名复杂表达式 ──
locals {
  is_production = local.environment == "prod"
  log_level     = local.is_production ? "warn" : "debug"
  instance_type = local.is_production ? "m5.large" : "t3.micro"
}

output "named_expressions" {
  value = {
    is_production = local.is_production
    log_level     = local.log_level
    instance_type = local.instance_type
  }
}

# ── 5. 预处理输入数据 ──
variable "raw_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8", " 172.16.0.0/12 ", "  192.168.0.0/16  "]
}

locals {
  # 去除每个 CIDR 的前后空格
  clean_cidrs = [for cidr in var.raw_cidrs : trimspace(cidr)]

  # 构建 key=value 格式的标签字符串
  tag_strings = [for k, v in local.common_tags : "${k}=${v}"]
}

output "preprocessed" {
  value = {
    clean_cidrs = local.clean_cidrs
    tag_strings = local.tag_strings
  }
}

# ── 6. 链式引用 ──
locals {
  base_name   = "${local.project}-${local.environment}"
  bucket_name = "${local.base_name}-data"
  log_bucket  = "${local.base_name}-logs"
}

output "chained" {
  value = {
    base_name   = local.base_name
    bucket_name = local.bucket_name
    log_bucket  = local.log_bucket
  }
}
