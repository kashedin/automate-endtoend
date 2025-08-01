# Storage Module Outputs

# Static Website Bucket
output "static_website_bucket_id" {
  description = "ID of the static website S3 bucket"
  value       = aws_s3_bucket.static_website.id
}

output "static_website_bucket_arn" {
  description = "ARN of the static website S3 bucket"
  value       = aws_s3_bucket.static_website.arn
}

output "static_website_bucket_domain_name" {
  description = "Domain name of the static website S3 bucket"
  value       = aws_s3_bucket.static_website.bucket_domain_name
}

output "static_website_url" {
  description = "URL of the static website"
  value       = "http://${aws_s3_bucket.static_website.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}

# Logs and Backups Bucket
output "logs_backups_bucket_id" {
  description = "ID of the logs and backups S3 bucket"
  value       = aws_s3_bucket.logs_backups.id
}

output "logs_backups_bucket_arn" {
  description = "ARN of the logs and backups S3 bucket"
  value       = aws_s3_bucket.logs_backups.arn
}

# Application Assets Bucket
output "app_assets_bucket_id" {
  description = "ID of the application assets S3 bucket"
  value       = aws_s3_bucket.app_assets.id
}

output "app_assets_bucket_arn" {
  description = "ARN of the application assets S3 bucket"
  value       = aws_s3_bucket.app_assets.arn
}

# Bucket names for reference
output "bucket_names" {
  description = "Map of all bucket names"
  value = {
    static_website = aws_s3_bucket.static_website.id
    logs_backups   = aws_s3_bucket.logs_backups.id
    app_assets     = aws_s3_bucket.app_assets.id
  }
}

# Bucket ARNs for IAM policies
output "bucket_arns" {
  description = "Map of all bucket ARNs"
  value = {
    static_website = aws_s3_bucket.static_website.arn
    logs_backups   = aws_s3_bucket.logs_backups.arn
    app_assets     = aws_s3_bucket.app_assets.arn
  }
}

# Data source for current region
data "aws_region" "current" {}

# Main bucket outputs
output "main_bucket_id" {
  description = "ID of the main S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "main_bucket_arn" {
  description = "ARN of the main S3 bucket"
  value       = aws_s3_bucket.main.arn
}

# CloudFront distribution outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static_website.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static_website.domain_name
}