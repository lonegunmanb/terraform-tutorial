# 此文件用于测试验证，请勿修改

output "check_instance_id" {
  value = aws_instance.exercise.id
}

output "check_instance_type" {
  value = aws_instance.exercise.instance_type
}

output "check_instance_name" {
  value = var.instance_name
}

output "check_owner" {
  value     = var.owner
  sensitive = true
}
