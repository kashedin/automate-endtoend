# Storage Module Outputs - Minimal Version for Sandbox Testing

# Static Website Bucket (placeholder)
output "static_website_bucket_id" {
  description = "ID of the static website S3 bucket (placeholder)"
  value       = local.placeholder_bucket_name
}

output "static_website_bucket_arn" {
  description = "ARN of the static website S3 bucket (placeholder)"
  value       = local.placeholder_arn
}

output "static_website_bucket_domain_name" {
  description = "Domain name of the static website S3 bucket (placeholder)"
  value       = local.placeholder_domain_name
}

output "static_website_bucket_regional_domain_name" {
  description = "Regional domain name of the static website S3 bucket (placeholder)"
  value       = local.placeholder_domain_name
}

output "static_website_url" {
  description = "URL of the static website (placeholder)"
  value       = "http://${local.placeholder_bucket_name}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}

# Logs and Backups Bucket (placeholder)
output "logs_backups_bucket_id" {
  description = "ID of the logs and backups S3 bucket (placeholder)"
  value       = local.placeholder_bucket_name
}

output "logs_backups_bucket_arn" {
  description = "ARN of the logs and backups S3 bucket (placeholder)"
  value       = local.placeholder_arn
}

# Application Assets Bucket (placeholder)
output "app_assets_bucket_id" {
  description = "ID of the application assets S3 bucket (placeholder)"
  value       = local.placeholder_bucket_name
}

output "app_assets_bucket_arn" {
  description = "ARN of the application assets S3 bucket (placeholder)"
  value       = local.placeholder_arn
}

# Access Logs Bucket (placeholder)
output "access_logs_bucket_id" {
  description = "ID of the access logs S3 bucket (placeholder)"
  value       = local.placeholder_bucket_name
}

output "access_logs_bucket_name" {
  description = "Name of the access logs S3 bucket (placeholder)"
  value       = local.placeholder_bucket_name
}

output "access_logs_bucket_arn" {
  description = "ARN of the access logs S3 bucket (placeholder)"
  value       = local.placeholder_arn
}

# Bucket names for reference (placeholder)
output "bucket_names" {
  description = "Map of all bucket names (placeholder)"
  value = {
    static_website = local.placeholder_bucket_name
    logs_backups   = local.placeholder_bucket_name
    app_assets     = local.placeholder_bucket_name
    access_logs    = local.placeholder_bucket_name
  }
}

# Bucket ARNs for IAM policies (placeholder)
output "bucket_arns" {
  description = "Map of all bucket ARNs (placeholder)"
  value = {
    static_website = local.placeholder_arn
    logs_backups   = local.placeholder_arn
    app_assets     = local.placeholder_arn
    access_logs    = local.placeholder_arn
  }
}

# Main bucket outputs (placeholder)
output "main_bucket_id" {
  description = "ID of the main S3 bucket (placeholder)"
  value       = local.placeholder_bucket_name
}

output "main_bucket_arn" {
  description = "ARN of the main S3 bucket (placeholder)"
  value       = local.placeholder_arn
}

# CloudFront distribution outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.placeholder.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.placeholder.domain_name
}