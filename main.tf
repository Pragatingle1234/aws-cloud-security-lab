# AWS S3 Security Infrastructure as Code
# Purpose: Deploy secure S3 buckets with best practices using Terraform
# Author: AWS Cloud Security Lab
# Date: April 2026
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Variables can be overridden:
#   terraform apply -var="bucket_name=my-secure-bucket"

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################################################
# Variables
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]*$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be 3-63 characters, lowercase letters, numbers, hyphens, and periods only."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  description = "Require MFA for object deletion"
  type        = bool
  default     = false # Requires root user account
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (optional, uses AES-256 if not provided)"
  type        = string
  default     = ""
}

variable "allowed_principals" {
  description = "ARN of principals allowed to access the bucket"
  type        = list(string)
  default     = []
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail data events for S3"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

###############################################################################
# Data Sources
###############################################################################

data "aws_caller_identity" "current" {}

###############################################################################
# S3 Bucket - Main
###############################################################################

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

###############################################################################
# Block Public Access
###############################################################################

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################################################
# Bucket Versioning
###############################################################################

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status     = var.enable_versioning ? "Enabled" : "Suspended"
    mfa_delete = var.enable_mfa_delete ? "Enabled" : "Disabled"
  }

  lifecycle {
    ignore_changes = [versioning_configuration[0].mfa_delete]
  }
}

###############################################################################
# Server-Side Encryption
###############################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm       = var.kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id   = var.kms_key_arn != "" ? var.kms_key_arn : null
    }
    bucket_key_enabled = true
  }
}

###############################################################################
# Logging Bucket
###############################################################################

resource "aws_s3_bucket" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${var.bucket_name}-logs"

  tags = merge(
    var.tags,
    {
      Name    = "${var.bucket_name}-logs"
      Purpose = "Access Logs"
    }
  )
}

resource "aws_s3_bucket_versioning" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################################################
# Access Logging
###############################################################################

resource "aws_s3_bucket_logging" "main" {
  count          = var.enable_logging ? 1 : 0
  bucket         = aws_s3_bucket.main.id
  target_bucket  = aws_s3_bucket.logs[0].id
  target_prefix  = "s3-access-logs/${var.bucket_name}/"

  depends_on = [
    aws_s3_bucket_public_access_block.logs
  ]
}

###############################################################################
# Bucket ACL
###############################################################################

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"

  depends_on = [aws_s3_bucket_public_access_block.main]
}

###############################################################################
# Bucket Policy - Restrict to Specific Principals
###############################################################################

data "aws_iam_policy_document" "main" {
  statement {
    sid    = "EnforcedTLS"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = length(var.allowed_principals) > 0 ? var.allowed_principals : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [var.kms_key_arn != "" ? "aws:kms" : "AES256"]
    }
  }

  statement {
    sid    = "DenyIncorrectKMSKey"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = length(var.allowed_principals) > 0 ? var.allowed_principals : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [var.kms_key_arn]
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_principals) > 0 ? [1] : []
    content {
      sid    = "AllowSpecificPrincipals"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.allowed_principals
      }
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.main.arn,
        "${aws_s3_bucket.main.arn}/*"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main.json
}

###############################################################################
# Lifecycle Rules
###############################################################################

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "DeleteOldVersions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "ExpireTemp"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 7
    }
  }
}

###############################################################################
# Lifecycle Rules for Logs Bucket
###############################################################################

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "DeleteOldLogs"
    status = "Enabled"

    expiration {
      days = 365
    }
  }

  rule {
    id     = "TransitionToIA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "TransitionToGlacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

###############################################################################
# CloudTrail for S3 Data Events
###############################################################################

resource "aws_cloudtrail" "s3" {
  count           = var.enable_cloudtrail ? 1 : 0
  name            = "${var.bucket_name}-trail"
  s3_bucket_name  = aws_s3_bucket.cloudtrail_logs[0].id
  is_multi_region = true
  enable_logging  = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

resource "aws_cloudtrail_event_selector" "s3" {
  count           = var.enable_cloudtrail ? 1 : 0
  trail_name      = aws_cloudtrail.s3[0].name
  read_write_type = "All"

  data_resource {
    type   = "AWS::S3::Object"
    values = ["${aws_s3_bucket.main.arn}/*"]
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "${var.bucket_name}-cloudtrail-logs"

  tags = merge(
    var.tags,
    {
      Name    = "${var.bucket_name}-cloudtrail-logs"
      Purpose = "CloudTrail Logs"
    }
  )
}

data "aws_iam_policy_document" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  statement {
    sid    = "AllowCloudTrailPutObject"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs[0].arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "AllowCloudTrailGetBucketVersioning"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketVersioning"]
    resources = [aws_s3_bucket.cloudtrail_logs[0].arn]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id
  policy = data.aws_iam_policy_document.cloudtrail[0].json
}

###############################################################################
# Tags
###############################################################################

resource "aws_s3_bucket_tagging" "main" {
  bucket = aws_s3_bucket.main.id

  tagging {
    tags = merge(
      var.tags,
      {
        LastSecurityAudit = formatdate("YYYY-MM-DD", timestamp())
        SecurityLevel     = "High"
      }
    )
  }
}

###############################################################################
# Outputs
###############################################################################

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "logging_bucket" {
  description = "Name of the logging bucket"
  value       = var.enable_logging ? aws_s3_bucket.logs[0].id : "Not enabled"
}

output "security_status" {
  description = "Security configuration status"
  value = {
    block_public_access = true
    encryption_enabled  = true
    versioning_enabled  = var.enable_versioning
    logging_enabled     = var.enable_logging
    cloudtrail_enabled  = var.enable_cloudtrail
    encryption_type     = var.kms_key_arn != "" ? "KMS" : "AES256"
  }
}

output "regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}
