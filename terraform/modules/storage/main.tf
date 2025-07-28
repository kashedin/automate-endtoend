# Storage Module - S3 Buckets
# This module creates S3 buckets for application storage

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "static_website" {
  bucket        = "${var.environment}-static-website-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-static-website"
    Purpose = "static-website"
  })
}

resource "aws_s3_bucket_versioning" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static_website]
}

# S3 Bucket for Application Logs and Backups
resource "aws_s3_bucket" "logs_backups" {
  bucket        = "${var.environment}-logs-backups-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-logs-backups"
    Purpose = "logs-backups"
  })
}

resource "aws_s3_bucket_versioning" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_backups" {
  bucket = aws_s3_bucket.logs_backups.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.backup_retention_days
    }
  }
}

# S3 Bucket for Application Assets
resource "aws_s3_bucket" "app_assets" {
  bucket        = "${var.environment}-app-assets-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_buckets

  tags = merge(var.common_tags, {
    Name    = "${var.environment}-app-assets"
    Purpose = "application-assets"
  })
}

resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload sample static website content
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_website.id
  key          = "index.html"
  content_type = "text/html"
  content = templatefile("${path.module}/static_content/index.html", {
    environment = var.environment
  })

  tags = merge(var.common_tags, {
    Name = "index.html"
  })
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.static_website.id
  key          = "error.html"
  content_type = "text/html"
  content = templatefile("${path.module}/static_content/error.html", {
    environment = var.environment
  })

  tags = merge(var.common_tags, {
    Name = "error.html"
  })
}