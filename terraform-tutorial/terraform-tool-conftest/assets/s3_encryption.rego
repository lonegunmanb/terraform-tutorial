package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  actions := resource.change.actions
  actions[_] == "create"

  bucket_address := resource.address
  not has_encryption(bucket_address)

  msg := sprintf("S3 桶 '%s' 缺少服务端加密配置（aws_s3_bucket_server_side_encryption_configuration）", [bucket_address])
}

has_encryption(bucket_address) {
  res := input.resource_changes[_]
  res.type == "aws_s3_bucket_server_side_encryption_configuration"
  res.change.after.bucket == bucket_address
}

has_encryption(bucket_address) {
  res := input.configuration.root_module.resources[_]
  res.type == "aws_s3_bucket_server_side_encryption_configuration"
  some expr in res.expressions.bucket.references
  contains(expr, bucket_address)
}
