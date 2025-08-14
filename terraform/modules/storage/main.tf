# Storage Module - S3 Buckets (Sandbox Compatible Version)
# This module creates S3 buckets optimized for AWS sandbox environments

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

# Simplified S3 Bucket for Access Logs (Sandbox Compatible)
resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.environment}-access-logs-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-access-logs"
    Purpose = "access-logs"
  })

  lifecycle {
    ignore_changes = [
      # Ignore object lock configuration changes to avoid permission issues
      object_lock_configuration,
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Simplified S3 Bucket for Static Website Hosting (Sandbox Compatible)
resource "aws_s3_bucket" "static_website" {
  bucket        = "${var.environment}-static-website-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-static-website"
    Purpose = "static-website"
  })

  lifecycle {
    ignore_changes = [
      # Ignore object lock configuration changes to avoid permission issues
      object_lock_configuration,
    ]
  }
}

resource "aws_s3_bucket_versioning" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

# Simplified S3 Bucket for Application Logs and Backups (Sandbox Compatible)
resource "aws_s3_bucket" "logs_backups" {
  bucket        = "${var.environment}-logs-backups-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-logs-backups"
    Purpose = "logs-backups"
  })

  lifecycle {
    ignore_changes = [
      # Ignore object lock configuration changes to avoid permission issues
      object_lock_configuration,
    ]
  }
}

resource "aws_s3_bucket_versioning" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Simplified S3 Bucket for Application Assets (Sandbox Compatible)
resource "aws_s3_bucket" "app_assets" {
  bucket        = "${var.environment}-app-assets-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-app-assets"
    Purpose = "application-assets"
  })

  lifecycle {
    ignore_changes = [
      # Ignore object lock configuration changes to avoid permission issues
      object_lock_configuration,
    ]
  }
}

resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

# Main S3 Bucket (Sandbox Compatible)
resource "aws_s3_bucket" "main" {
  # Use a unique name to avoid conflicts
  bucket        = "${var.environment}-main-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-main-bucket"
    Purpose = "main-bucket"
  })

  lifecycle {
    ignore_changes = [
      # Ignore object lock configuration changes to avoid permission issues
      object_lock_configuration,
    ]
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.bucket_config.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "static_website" {
  name                              = "${var.environment}-static-website-oac"
  description                       = "OAC for static website S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for Static Website
resource "aws_cloudfront_distribution" "static_website" {
  origin {
    domain_name              = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_website.id
    origin_id                = "S3-${aws_s3_bucket.static_website.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

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



# SNS notifications disabled for sandbox compatibility

# Data source for current AWS account
data "aws_caller_identity" "current" {}