# Storage Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "force_destroy_buckets" {
  description = "Force destroy S3 buckets even if they contain objects"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain log files"
  type        = number
  default     = 90
}

variable "backup_retention_days" {
  description = "Number of days to retain backup files"
  type        = number
  default     = 365
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for critical buckets"
  type        = bool
  default     = false
}

variable "replication_destination_region" {
  description = "Destination region for cross-region replication"
  type        = string
  default     = "us-west-2"
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# Bucket configuration
variable "bucket_config" {
  description = "S3 bucket configuration"
  type = object({
    versioning_enabled  = bool
    encryption_enabled  = bool
    public_read_enabled = bool
    lifecycle_enabled   = bool
    logging_enabled     = bool
  })

  default = {
    versioning_enabled  = true
    encryption_enabled  = true
    public_read_enabled = false
    lifecycle_enabled   = true
    logging_enabled     = true
  }
}

# Use enable_cross_region_replication to conditionally create replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0
  bucket = aws_s3_bucket.main.id

  role = aws_iam_role.replication.arn

  rules {
    id     = "replication"
    status = "Enabled"

    destination {
      bucket        = var.bucket_config["destination_bucket"]
      storage_class = "STANDARD"
      region        = var.replication_destination_region
    }
  }
}