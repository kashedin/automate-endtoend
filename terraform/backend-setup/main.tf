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
  byte_length = 4
}

# S3 bucket for Terraform state (simplified for lab environment)
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-state-kashedin-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# S3 bucket versioning (separate resource for better compatibility)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock-kashedin"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-state-lock-kashedin"
    Description = "DynamoDB table for Terraform state locking"
  }
}