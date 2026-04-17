# ── 第二步：网络层 + Web 层提取为模块 ──────────────────────────────────────
# 每个 moved 块告诉 Terraform：资源从旧地址搬到了新地址。
# 状态文件会更新地址，但不会销毁或重建任何基础设施资源。

# 网络层 ─────────────────────────────────────────────────────────────────────

moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.this
}

moved {
  from = aws_internet_gateway.main
  to   = module.networking.aws_internet_gateway.this
}

# 子网从独立资源变为 for_each（以 CIDR 为 key）
moved {
  from = aws_subnet.public_a
  to   = module.networking.aws_subnet.public["10.0.1.0/24"]
}

moved {
  from = aws_subnet.public_b
  to   = module.networking.aws_subnet.public["10.0.2.0/24"]
}

moved {
  from = aws_subnet.private_a
  to   = module.networking.aws_subnet.private["10.0.11.0/24"]
}

moved {
  from = aws_subnet.private_b
  to   = module.networking.aws_subnet.private["10.0.12.0/24"]
}

moved {
  from = aws_route_table.public
  to   = module.networking.aws_route_table.public
}

# 路由表关联也跟随子网进入 for_each
moved {
  from = aws_route_table_association.public_a
  to   = module.networking.aws_route_table_association.public["10.0.1.0/24"]
}

moved {
  from = aws_route_table_association.public_b
  to   = module.networking.aws_route_table_association.public["10.0.2.0/24"]
}

# Web 层 ──────────────────────────────────────────────────────────────────────

moved {
  from = aws_security_group.alb
  to   = module.web.aws_security_group.alb
}

moved {
  from = aws_security_group.app
  to   = module.web.aws_security_group.app
}

moved {
  from = aws_security_group.data
  to   = module.web.aws_security_group.data
}

# ALB 资源名从 web 改为 this（模块内无需重复层级前缀）
moved {
  from = aws_lb.web
  to   = module.web.aws_lb.this
}

moved {
  from = aws_lb_target_group.app
  to   = module.web.aws_lb_target_group.app
}

moved {
  from = aws_lb_listener.http
  to   = module.web.aws_lb_listener.http
}

moved {
  from = aws_instance.app
  to   = module.web.aws_instance.app
}

moved {
  from = aws_lb_target_group_attachment.app
  to   = module.web.aws_lb_target_group_attachment.app
}
