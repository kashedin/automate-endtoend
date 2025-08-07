# Simplified Terraform Backend for AWS Academy Sandbox
# Avoids object lock configuration issues

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
  region = "us-west-2"
}

# Generate random suffix for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Simple S3 bucket for Terraform state (no advanced features)
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "tf-state-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# Simple DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "tf-state-lock-${random_id.bucket_suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}