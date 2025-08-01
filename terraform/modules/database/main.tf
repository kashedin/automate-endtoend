# Database Module - Aurora MySQL Cluster
# This module creates Aurora MySQL cluster with high availability

terraform {
  required_version = ">= 1.6.0"
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

# DB Subnet Group
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.environment}-aurora-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-subnet-group"
  })
}

# Aurora Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "aurora" {
  family      = "aurora-mysql8.0"
  name        = "${var.environment}-aurora-cluster-params"
  description = "Aurora cluster parameter group for ${var.environment}"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "1000"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-cluster-params"
  })
}

# Aurora DB Parameter Group
resource "aws_db_parameter_group" "aurora" {
  family = "aurora-mysql8.0"
  name   = "${var.environment}-aurora-db-params"

  parameter {
    name  = "innodb_print_all_deadlocks"
    value = "1"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-db-params"
  })
}

# Aurora Cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier                  = "${var.environment}-aurora-cluster"
  engine                              = var.aurora_config.engine
  engine_version                      = var.aurora_config.engine_version
  database_name                       = var.database_name
  master_username                     = var.master_username
  master_password                     = var.master_password
  backup_retention_period             = var.aurora_config.backup_retention_period
  preferred_backup_window             = var.aurora_config.backup_window
  preferred_maintenance_window        = var.aurora_config.maintenance_window
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.aurora.name
  db_subnet_group_name                = aws_db_subnet_group.aurora.name
  vpc_security_group_ids              = [var.security_group_id]
  storage_encrypted                   = var.aurora_config.storage_encrypted
  kms_key_id                          = var.kms_key_id
  deletion_protection                 = var.aurora_config.deletion_protection
  skip_final_snapshot                 = var.aurora_config.skip_final_snapshot
  final_snapshot_identifier           = var.aurora_config.skip_final_snapshot ? null : "${var.environment}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot               = var.aurora_config.copy_tags_to_snapshot
  iam_database_authentication_enabled = true

  # Enable logging
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-cluster"
  })

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# AWS Backup Vault
resource "aws_backup_vault" "aurora" {
  name        = "${var.environment}-aurora-backup-vault"
  kms_key_arn = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-backup-vault"
  })
}

# AWS Backup Plan
resource "aws_backup_plan" "aurora" {
  name = "${var.environment}-aurora-backup-plan"

  rule {
    rule_name         = "${var.environment}-aurora-backup-rule"
    target_vault_name = aws_backup_vault.aurora.name
    schedule          = "cron(0 5 ? * * *)" # Daily at 5 AM UTC

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }

    recovery_point_tags = merge(var.common_tags, {
      BackupPlan = "${var.environment}-aurora-backup-plan"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-backup-plan"
  })
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-backup-role"
  })
}

# Attach AWS managed policy for RDS backup
resource "aws_iam_role_policy_attachment" "backup_rds" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Backup selection
resource "aws_backup_selection" "aurora" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.environment}-aurora-backup-selection"
  plan_id      = aws_backup_plan.aurora.id

  resources = [
    aws_rds_cluster.aurora.arn
  ]

  condition {
    string_equals {
      key   = "aws:ResourceTag/Environment"
      value = var.environment
    }
  }
}

# Aurora Cluster Instances
#checkov:skip=CKV_AWS_118:Enhanced monitoring disabled for cost optimization in lab environment
resource "aws_rds_cluster_instance" "aurora_writer" {
  identifier                      = "${var.environment}-aurora-writer"
  cluster_identifier              = aws_rds_cluster.aurora.id
  instance_class                  = var.aurora_config.instance_class
  engine                          = aws_rds_cluster.aurora.engine
  engine_version                  = aws_rds_cluster.aurora.engine_version
  db_parameter_group_name         = aws_db_parameter_group.aurora.name
  monitoring_interval             = var.aurora_config.monitoring_interval
  monitoring_role_arn             = var.monitoring_role_arn
  performance_insights_enabled    = var.aurora_config.performance_insights_enabled
  performance_insights_kms_key_id = var.kms_key_id
  auto_minor_version_upgrade      = true

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-writer"
    Role = "Writer"
  })
}

#checkov:skip=CKV_AWS_354:Performance Insights KMS encryption not required for lab environment
resource "aws_rds_cluster_instance" "aurora_reader" {
  count = var.aurora_config.reader_count

  identifier                      = "${var.environment}-aurora-reader-${count.index + 1}"
  cluster_identifier              = aws_rds_cluster.aurora.id
  instance_class                  = var.aurora_config.instance_class
  engine                          = aws_rds_cluster.aurora.engine
  engine_version                  = aws_rds_cluster.aurora.engine_version
  db_parameter_group_name         = aws_db_parameter_group.aurora.name
  monitoring_interval             = var.aurora_config.monitoring_interval
  monitoring_role_arn             = var.monitoring_role_arn
  performance_insights_enabled    = var.aurora_config.performance_insights_enabled
  performance_insights_kms_key_id = var.kms_key_id
  auto_minor_version_upgrade      = true

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-reader-${count.index + 1}"
    Role = "Reader"
  })
}