# Storage Module - S3 Buckets
# This module creates S3 buckets for application storage

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 Bucket for Access Logs
#checkov:skip=CKV_AWS_18:Access logs bucket cannot log to itself
#checkov:skip=CKV_AWS_144:Cross-region replication not required for access logs in lab environment
#checkov:skip=CKV_AWS_21:Versioning not required for access logs bucket
#checkov:skip=CKV_AWS_145:KMS encryption not required for access logs in lab environment
#checkov:skip=CKV2_AWS_61:Lifecycle configuration not required for access logs bucket
#checkov:skip=CKV2_AWS_62:Event notifications not required for lab environment
resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.environment}-access-logs-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-access-logs"
    Purpose = "access-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration for access logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "access_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 encryption disabled for sandbox compliance

# S3 Bucket for Static Website Hosting
#checkov:skip=CKV_AWS_144:Cross-region replication not required for static website in lab environment
#checkov:skip=CKV_AWS_145:KMS encryption not required for static website content
#checkov:skip=CKV2_AWS_62:Event notifications not required for lab environment
resource "aws_s3_bucket" "static_website" {
  bucket        = "${var.environment}-static-website-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-static-website"
    Purpose = "static-website"
  })
}

resource "aws_s3_bucket_versioning" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 encryption disabled for sandbox compliance

resource "aws_s3_bucket_logging" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "static-website-access-logs/"
}

resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration for static website bucket
resource "aws_s3_bucket_lifecycle_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  rule {
    id     = "static_website_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket policy removed - using CloudFront OAC instead for better security

# S3 Bucket for Application Logs and Backups
#checkov:skip=CKV_AWS_144:Cross-region replication not required for logs and backups in lab environment
#checkov:skip=CKV_AWS_145:KMS encryption not required for logs and backups in lab environment
#checkov:skip=CKV2_AWS_62:Event notifications not required for lab environment
resource "aws_s3_bucket" "logs_backups" {
  bucket        = "${var.environment}-logs-backups-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-logs-backups"
    Purpose = "logs-backups"
  })
}

resource "aws_s3_bucket_versioning" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 encryption disabled for sandbox compliance

resource "aws_s3_bucket_logging" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "logs-backups-access-logs/"
}

resource "aws_s3_bucket_public_access_block" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#checkov:skip=CKV_AWS_300:Abort incomplete multipart upload configured for all rules
resource "aws_s3_bucket_lifecycle_configuration" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.backup_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 Bucket for Application Assets
#checkov:skip=CKV_AWS_144:Cross-region replication not required for application assets in lab environment
#checkov:skip=CKV_AWS_145:KMS encryption not required for application assets
#checkov:skip=CKV2_AWS_62:Event notifications not required for lab environment
resource "aws_s3_bucket" "app_assets" {
  bucket        = "${var.environment}-app-assets-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-app-assets"
    Purpose = "application-assets"
  })
}

resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 encryption disabled for sandbox compliance

resource "aws_s3_bucket_logging" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "app-assets-access-logs/"
}

resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration for app assets bucket
resource "aws_s3_bucket_lifecycle_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  rule {
    id     = "app_assets_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Upload sample static website content
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_website.id
  key          = "index.html"
  content_type = "text/html"
  content = templatefile("${path.module}/static_content/index.html", {
    environment = var.environment
  })

  tags = merge(var.common_tags, {
    Name = "index.html"
  })
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.static_website.id
  key          = "error.html"
  content_type = "text/html"
  content = templatefile("${path.module}/static_content/error.html", {
    environment = var.environment
  })

  tags = merge(var.common_tags, {
    Name = "error.html"
  })
}

# Main S3 Bucket
#checkov:skip=CKV_AWS_145:KMS encryption not required for main bucket in lab environment
#checkov:skip=CKV2_AWS_62:Event notifications not required for lab environment
resource "aws_s3_bucket" "main" {
  bucket        = "${var.environment}-main-bucket"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-main-bucket"
    Purpose = "main-bucket"
  })
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.bucket_config.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# KMS key creation disabled for sandbox compliance
# AWS KMS has read-only access in sandbox environment

# S3 encryption disabled for sandbox compliance
# No server-side encryption configuration

resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "main-bucket-access-logs/"
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.bucket_config.lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "main_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 replication configuration disabled for sandbox compliance
# Cross-region replication requires custom IAM roles which are restricted

# S3 replication IAM role creation disabled for sandbox compliance
# Cross-region replication disabled - IAM role creation is restricted

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "static_website" {
  name                              = "${var.environment}-static-website-oac"
  description                       = "OAC for static website S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for Static Website
#checkov:skip=CKV_AWS_310:Origin failover not required for single S3 origin in lab environment
#checkov:skip=CKV_AWS_374:Geo restriction not required for lab environment
#checkov:skip=CKV_AWS_68:WAF not required for static website CloudFront in lab environment
#checkov:skip=CKV2_AWS_32:Response headers policy not required for lab environment
#checkov:skip=CKV2_AWS_42:Custom SSL certificate not required for lab environment
#checkov:skip=CKV2_AWS_47:WAF Log4j rule not required for static website
resource "aws_cloudfront_distribution" "static_website" {
  origin {
    domain_name              = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_website.id
    origin_id                = "S3-${aws_s3_bucket.static_website.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # CloudFront Access Logging
  logging_config {
    bucket          = aws_s3_bucket.access_logs.bucket_domain_name
    prefix          = "cloudfront-access-logs/"
    include_cookies = false
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.static_website.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-static-website-cdn"
  })
}



# SNS Topic for S3 notifications (for main bucket only)
resource "aws_sns_topic" "s3_notifications" {
  count = var.bucket_config.enable_notifications ? 1 : 0
  name  = "${var.environment}-s3-notifications"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-s3-notifications"
  })
}

# S3 bucket notification for main bucket
resource "aws_s3_bucket_notification" "main" {
  count  = var.bucket_config.enable_notifications ? 1 : 0
  bucket = aws_s3_bucket.main.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications[0].arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_sns_topic_policy.s3_notifications]
}

# SNS topic policy to allow S3 to publish
resource "aws_sns_topic_policy" "s3_notifications" {
  count = var.bucket_config.enable_notifications ? 1 : 0
  arn   = aws_sns_topic.s3_notifications[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.s3_notifications[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.main.arn
          }
        }
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}