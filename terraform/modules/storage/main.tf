# Storage Module - Minimal Configuration for Sandbox Testing
# This version removes S3 buckets to test the rest of the infrastructure without S3 object lock issues

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

# Random ID for unique naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create a simple CloudFront distribution without S3 origin for testing
resource "aws_cloudfront_distribution" "placeholder" {
  origin {
    domain_name = "example.com"
    origin_id   = "placeholder-origin"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "placeholder-origin"
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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = var.common_tags
}

# Placeholder locals for outputs
locals {
  placeholder_bucket_name = "placeholder-bucket-${random_id.bucket_suffix.hex}"
  placeholder_domain_name = "placeholder.s3.amazonaws.com"
  placeholder_arn = "arn:aws:s3:::placeholder-bucket-${random_id.bucket_suffix.hex}"
}