package main

import rego.v1

deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  actions := resource.change.actions
  actions[_] == "create"

  # Check: no companion aws_s3_bucket_versioning resource references this bucket
  bucket_address := resource.address
  not has_versioning(bucket_address)

  msg := sprintf("S3 桶 '%s' 缺少版本控制配置（aws_s3_bucket_versioning）", [bucket_address])
}

has_versioning(bucket_address) if {
  res := input.resource_changes[_]
  res.type == "aws_s3_bucket_versioning"
  res.change.after.bucket == bucket_address
}

has_versioning(bucket_address) if {
  res := input.configuration.root_module.resources[_]
  res.type == "aws_s3_bucket_versioning"
  some expr in res.expressions.bucket.references
  contains(expr, bucket_address)
}
