# 第二步：理解并修复问题

TFLint 报告了以下问题，逐一修复它们：

### 问题 1：变量缺少 description

```
variable "BucketName" 没有 description
```

**修复**：给变量添加 `description` 字段：

```hcl
variable "BucketName" {
  type        = string
  default     = "my-lint-test-bucket"
  description = "Name of the S3 bucket to create"
}
```

### 问题 2：变量命名不符合 snake_case

```
variable "BucketName" 不符合 snake_case 约定
```

**修复**：重命名变量为 `bucket_name`，同时更新所有引用：

```hcl
variable "bucket_name" {
  type        = string
  default     = "my-lint-test-bucket"
  description = "Name of the S3 bucket to create"
}
```

别忘了更新 `aws_s3_bucket.example` 中的引用：`var.bucket_name`

### 问题 3：未使用的变量

```
variable "unused_region" is declared but not used
```

**修复**：直接删除 `unused_region` 变量声明。

### 问题 4：废弃属性

如有 `bucket_domain_name` 相关告警，将 output 改为使用推荐的替代属性，或先删除这个 output。

用编辑器或 `sed` 完成上述修改。
