output "vpc_id" {
  value = module.networking.vpc_id
}

output "alb_dns_name" {
  value = module.web.alb_dns_name
}

output "static_bucket" {
  value = module.storage.static_bucket_name
}

output "backup_bucket" {
  value = module.storage.backup_bucket_name
}

output "task_queue_url" {
  value = module.data.task_queue_url
}

output "users_table" {
  value = module.data.users_table_name
}

output "app_role_arn" {
  value = module.security.app_role_arn
}
