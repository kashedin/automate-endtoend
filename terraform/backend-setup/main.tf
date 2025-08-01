# Simplified Terraform Backend Infrastructure Setup for Lab Environment
# This creates the S3 bucket and DynamoDB table needed for Terraform state management

terraform {
  required_version = ">= 1.0"
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

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "automated-cloud-infrastructure"
      Environment = "backend"
      ManagedBy   = "terraform"
      Owner       = "kashedin"
    }
  }
}

# Generate random suffix for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
  keepers = {
    timestamp = timestamp()
  }
}

# KMS key for DynamoDB encryption
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state DynamoDB table encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DynamoDB Service"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "terraform-state-dynamodb-key"
    Description = "KMS key for DynamoDB encryption"
  }
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state-dynamodb"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# S3 bucket for Terraform state (simplified for lab environment)
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-state-kashedin-${random_id.bucket_suffix.hex}"
  force_destroy = true

  # Skip object lock configuration for lab environment
  lifecycle {
    ignore_changes = [object_lock_configuration]
  }
}

# S3 bucket versioning (separate resource for better compatibility)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock-kashedin"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "terraform-state-lock-kashedin"
    Description = "DynamoDB table for Terraform state locking"
  }
}