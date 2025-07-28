# Terraform Backend Configuration
# This file configures remote state storage in S3 with DynamoDB locking
# Backend infrastructure should be created first using terraform/backend-setup/

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

  # Backend configuration is provided via GitHub Actions using secrets
  # For local development, use: terraform init -backend-config=backend.hcl
  backend "s3" {
    # Values populated by CI/CD pipeline:
    # bucket         = "${TF_STATE_BUCKET}" (from GitHub Secret)
    # key            = "environments/${environment}/terraform.tfstate"
    # region         = "${AWS_DEFAULT_REGION}" (from GitHub Secret)
    # dynamodb_table = "${TF_STATE_DYNAMODB_TABLE}" (from GitHub Secret)
    # encrypt        = true
  }
}

# Random ID for unique resource naming across environments
resource "random_id" "bucket_suffix" {
  byte_length = 8
}