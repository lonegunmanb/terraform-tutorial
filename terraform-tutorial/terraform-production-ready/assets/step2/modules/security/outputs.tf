output "app_role_arn" {
  value = aws_iam_role.app.arn
}

output "app_role_name" {
  value = aws_iam_role.app.name
}

output "app_instance_profile_name" {
  value = aws_iam_instance_profile.app.name
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}
