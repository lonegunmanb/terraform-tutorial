#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f main.tf ]; then
cat > main.tf <<'EOTF'
# S3 Static Website Module
#
# This module creates an S3 bucket configured for static website hosting,
# with optional versioning and lifecycle rules.

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

resource "aws_s3_bucket_versioning" "website" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = !var.allow_public_access
  block_public_policy     = !var.allow_public_access
  ignore_public_acls      = !var.allow_public_access
  restrict_public_buckets = !var.allow_public_access
}
EOTF
fi

if [ ! -f variables.tf ]; then
cat > variables.tf <<'EOTF'
variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket for static website hosting. Must be globally unique."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Whether to force destroy the bucket and all its contents when the resource is deleted."
}

variable "index_document" {
  type        = string
  default     = "index.html"
  description = "The name of the index document for the website."
}

variable "error_document" {
  type        = string
  default     = "error.html"
  description = "The name of the error document for the website."
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "Whether to enable versioning on the S3 bucket."
}

variable "allow_public_access" {
  type        = bool
  default     = false
  description = "Whether to allow public access to the S3 bucket. Set to true for public static websites."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to assign to all resources created by this module."
}
EOTF
fi

if [ ! -f outputs.tf ]; then
cat > outputs.tf <<'EOTF'
output "bucket_id" {
  value       = aws_s3_bucket.website.id
  description = "The ID of the S3 bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "The ARN of the S3 bucket."
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "The website endpoint URL of the S3 bucket."
}

output "website_domain" {
  value       = aws_s3_bucket_website_configuration.website.website_domain
  description = "The domain of the website endpoint."
}
EOTF
fi

# ── 2. Install terraform-docs ──
TFDOCS_VERSION="0.22.0"
curl -sSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz" \
  -o /tmp/terraform-docs.tar.gz
tar -xzf /tmp/terraform-docs.tar.gz -C /usr/local/bin terraform-docs
chmod +x /usr/local/bin/terraform-docs
rm -f /tmp/terraform-docs.tar.gz

install_theia_plugin
finish_setup
