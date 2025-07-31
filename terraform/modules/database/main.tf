# Database Module - Aurora MySQL Cluster
# This module creates Aurora MySQL cluster with high availability

terraform {
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

# Aurora Cluster Instances
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

resource "aws_rds_cluster_instance" "aurora_reader" {
  count = var.aurora_config.reader_count

  identifier                   = "${var.environment}-aurora-reader-${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.aurora.id
  instance_class               = var.aurora_config.instance_class
  engine                       = aws_rds_cluster.aurora.engine
  engine_version               = aws_rds_cluster.aurora.engine_version
  db_parameter_group_name      = aws_db_parameter_group.aurora.name
  monitoring_interval          = var.aurora_config.monitoring_interval
  monitoring_role_arn          = var.monitoring_role_arn
  performance_insights_enabled = var.aurora_config.performance_insights_enabled
  auto_minor_version_upgrade   = true

  tags = merge(var.common_tags, {
    Name = "${var.environment}-aurora-reader-${count.index + 1}"
    Role = "Reader"
  })
}