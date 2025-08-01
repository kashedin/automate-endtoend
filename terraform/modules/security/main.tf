# Security Module - IAM Roles, Security Groups, Parameter Store
# This module creates security infrastructure using existing lab role

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Data source for existing lab role
data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

# Instance profile using existing lab role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-instance-profile"
  role = data.aws_iam_role.lab_role.name

  tags = merge(var.common_tags, {
    Name = "${var.environment}-ec2-instance-profile"
  })
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-alb-sg"
    Tier = "Public"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count             = length(var.allowed_http_cidrs)
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from allowed CIDRs"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_http_cidrs[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ALB Egress Rules
resource "aws_vpc_security_group_egress_rule" "alb_to_web_http" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP to web tier"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web_https" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTPS to web tier"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
}

# Security Group for Web Tier
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = var.vpc_id
  description = "Security group for Web tier instances"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-web-sg"
    Tier = "Web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Web Tier Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP from ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  count             = var.enable_ssh_access ? length(var.allowed_ssh_cidrs) : 0
  security_group_id = aws_security_group.web.id
  description       = "SSH from allowed CIDRs"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ssh_cidrs[count.index]
}

# Web Tier Egress Rules
resource "aws_vpc_security_group_egress_rule" "web_https_updates" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS for updates"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_http_updates" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP for updates"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_to_app" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP to app tier"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

# Security Group for App Tier
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  vpc_id      = var.vpc_id
  description = "Security group for App tier instances"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-app-sg"
    Tier = "App"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# App Tier Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id            = aws_security_group.app.id
  description                  = "App port from Web tier"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  security_group_id = aws_security_group.app.id
  description       = "SSH from VPC"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}

# App Tier Egress Rules
resource "aws_vpc_security_group_egress_rule" "app_https_updates" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS for updates"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_http_updates" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP for updates"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_to_database" {
  security_group_id            = aws_security_group.app.id
  description                  = "MySQL to database"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.database.id
}

# Security Group for Database (Aurora)
resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for Aurora database cluster"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-database-sg"
    Tier = "Data"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id            = aws_security_group.database.id
  description                  = "MySQL from App tier"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

# KMS key for SSM Parameter encryption
resource "aws_kms_key" "ssm_parameters" {
  description             = "KMS key for SSM Parameter encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow SSM Service"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-ssm-parameters-kms"
  })
}

resource "aws_kms_alias" "ssm_parameters" {
  name          = "alias/${var.environment}-ssm-parameters"
  target_key_id = aws_kms_key.ssm_parameters.key_id
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Parameter Store - Database Username
resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.environment}/database/username"
  description = "Database username for ${var.environment} environment"
  type        = "SecureString"
  value       = var.db_username
  key_id      = aws_kms_key.ssm_parameters.arn

  tags = merge(var.common_tags, {
    Name = "${var.environment}-db-username"
  })
}

# Parameter Store - Database Password (SecureString)
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.environment}/database/password"
  description = "Database password for ${var.environment} environment"
  type        = "SecureString"
  value       = random_password.db_password.result
  key_id      = aws_kms_key.ssm_parameters.arn

  tags = merge(var.common_tags, {
    Name = "${var.environment}-db-password"
  })
}

# Parameter Store - Database Name
resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.environment}/database/name"
  description = "Database name for ${var.environment} environment"
  type        = "SecureString"
  value       = var.db_name
  key_id      = aws_kms_key.ssm_parameters.arn

  tags = merge(var.common_tags, {
    Name = "${var.environment}-db-name"
  })
}

# Parameter Store - Application Configuration
resource "aws_ssm_parameter" "app_config" {
  for_each = var.app_parameters

  name        = "/${var.environment}/app/${each.key}"
  description = "Application parameter: ${each.key}"
  type        = "SecureString"
  value       = each.value.value
  key_id      = aws_kms_key.ssm_parameters.arn

  tags = merge(var.common_tags, {
    Name = "${var.environment}-app-${each.key}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "custom_rules" {
  for_each          = { for idx, rule in var.security_rules : idx => rule }
  security_group_id = aws_security_group.web.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks[0]
  description       = each.value.description
}