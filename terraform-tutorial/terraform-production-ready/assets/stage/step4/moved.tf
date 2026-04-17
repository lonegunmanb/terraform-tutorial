# ── 第二步：网络层 + Web 层提取为模块 ──────────────────────────────────────

# 网络层
moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.this
}

moved {
  from = aws_internet_gateway.main
  to   = module.networking.aws_internet_gateway.this
}

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

moved {
  from = aws_route_table_association.public_a
  to   = module.networking.aws_route_table_association.public["10.0.1.0/24"]
}

moved {
  from = aws_route_table_association.public_b
  to   = module.networking.aws_route_table_association.public["10.0.2.0/24"]
}

# Web 层
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

# ── 第三步：数据层 + 存储层提取为模块 ──────────────────────────────────────

# 数据层
moved {
  from = aws_dynamodb_table.users
  to   = module.data.aws_dynamodb_table.users
}

# 存储层
moved {
  from = aws_s3_bucket.static_assets
  to   = module.storage.aws_s3_bucket.static
}

moved {
  from = aws_s3_bucket_versioning.static_assets
  to   = module.storage.aws_s3_bucket_versioning.static
}

moved {
  from = aws_s3_bucket.backups
  to   = module.storage.aws_s3_bucket.backups
}

moved {
  from = aws_s3_bucket_versioning.backups
  to   = module.storage.aws_s3_bucket_versioning.backups
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.backups
  to   = module.storage.aws_s3_bucket_lifecycle_configuration.backups
}

# ── 第四步：安全层提取为模块 ──────────────────────────────────────────────

moved {
  from = aws_secretsmanager_secret.db_credentials
  to   = module.security.aws_secretsmanager_secret.db_credentials
}

moved {
  from = aws_secretsmanager_secret_version.db_credentials
  to   = module.security.aws_secretsmanager_secret_version.db_credentials
}

moved {
  from = aws_iam_role.app
  to   = module.security.aws_iam_role.app
}

moved {
  from = aws_iam_policy.app
  to   = module.security.aws_iam_policy.app
}

moved {
  from = aws_iam_role_policy_attachment.app
  to   = module.security.aws_iam_role_policy_attachment.app
}

moved {
  from = aws_iam_instance_profile.app
  to   = module.security.aws_iam_instance_profile.app
}

moved {
  from = aws_ssm_parameter.app_config
  to   = module.security.aws_ssm_parameter.app_config
}

moved {
  from = aws_cloudwatch_log_group.app
  to   = module.security.aws_cloudwatch_log_group.app
}
