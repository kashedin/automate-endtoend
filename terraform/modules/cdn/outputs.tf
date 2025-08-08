# CDN Module Outputs

output "cloudfront_distribution_id" {
  description = "The identifier for the distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "The domain name corresponding to the distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "cloudfront_https_url" {
  description = "HTTPS URL for the application"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cloudfront_status" {
  description = "The current status of the distribution"
  value       = aws_cloudfront_distribution.main.status
}

output "origin_access_control_id" {
  description = "The unique identifier of the origin access control"
  value       = aws_cloudfront_origin_access_control.s3_oac.id
}