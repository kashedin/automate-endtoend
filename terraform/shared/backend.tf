# Terraform Backend Configuration
# This file configures remote state storage in S3 with DynamoDB locking

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

  # Backend configuration will be provided during terraform init
  # Example: terraform init -backend-config="bucket=my-terraform-state-bucket"
  backend "s3" {
    # bucket         = "terraform-state-${random_id.bucket_suffix.hex}"
    # key            = "infrastructure/terraform.tfstate"
    # region         = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

# Random ID for unique resource naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 bucket for Terraform state (only create if backend is not configured)
resource "aws_s3_bucket" "terraform_state" {
  count = var.create_state_bucket ? 1 : 0
  
  bucket        = "terraform-state-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
    Purpose     = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count = var.create_state_bucket ? 1 : 0
  
  bucket = aws_s3_bucket.terraform_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "terraform_state" {
  count = var.create_state_bucket ? 1 : 0
  
  bucket = aws_s3_bucket.terraform_state[0].id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count = var.create_state_bucket ? 1 : 0
  
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  count = var.create_state_bucket ? 1 : 0
  
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
    Purpose     = "terraform-state-lock"
  }
}

variable "create_state_bucket" {
  description = "Whether to create the S3 bucket and DynamoDB table for state management"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}