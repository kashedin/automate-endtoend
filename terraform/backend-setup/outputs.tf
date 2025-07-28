output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "backend_config" {
  description = "Backend configuration for use in other Terraform configurations"
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key            = "terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    encrypt        = true
  }
}

output "github_secrets" {
  description = "Values to add as GitHub Secrets"
  value = {
    TF_STATE_BUCKET           = aws_s3_bucket.terraform_state.bucket
    TF_STATE_DYNAMODB_TABLE   = aws_dynamodb_table.terraform_state_lock.name
    AWS_DEFAULT_REGION        = var.aws_region
  }
  sensitive = false
}