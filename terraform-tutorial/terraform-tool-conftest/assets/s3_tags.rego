package main

import rego.v1

required_tags := {"Environment", "ManagedBy"}

deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  actions := resource.change.actions
  actions[_] == "create"

  tags := object.get(resource.change.after, "tags", {})
  tag := required_tags[_]
  not tags[tag]

  msg := sprintf("S3 桶 '%s' 缺少必需标签 '%s'", [resource.address, tag])
}
