# Security Module - IAM Roles, Security Groups, Parameter Store
# This module creates security infrastructure using existing lab role

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

  # HTTP access from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound to web tier
  egress {
    description     = "HTTP to web tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # HTTPS outbound to web tier
  egress {
    description     = "HTTPS to web tier"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-alb-sg"
    Tier = "Public"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Web Tier
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = var.vpc_id
  description = "Security group for Web tier instances"

  # HTTP access from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSH access from bastion (if needed)
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTP outbound to app tier
  egress {
    description     = "HTTP to app tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # HTTPS outbound for updates
  egress {
    description = "HTTPS for updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound for updates
  egress {
    description = "HTTP for updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-web-sg"
    Tier = "Web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for App Tier
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  vpc_id      = var.vpc_id
  description = "Security group for App tier instances"

  # Application port access from Web tier only
  ingress {
    description     = "App port from Web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # SSH access from VPC
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # MySQL outbound to database
  egress {
    description     = "MySQL to database"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.database.id]
  }

  # HTTPS outbound for updates
  egress {
    description = "HTTPS for updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound for updates
  egress {
    description = "HTTP for updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-app-sg"
    Tier = "App"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Database (Aurora)
resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for Aurora database cluster"

  # MySQL access from App tier only
  ingress {
    description     = "MySQL from App tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # No outbound rules needed for database
  egress {
    description = "No outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-database-sg"
    Tier = "Data"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Parameter Store - Database Username
resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.environment}/database/username"
  description = "Database username for ${var.environment} environment"
  type        = "String"
  value       = var.db_username

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

  tags = merge(var.common_tags, {
    Name = "${var.environment}-db-password"
  })
}

# Parameter Store - Database Name
resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.environment}/database/name"
  description = "Database name for ${var.environment} environment"
  type        = "String"
  value       = var.db_name

  tags = merge(var.common_tags, {
    Name = "${var.environment}-db-name"
  })
}

# Parameter Store - Application Configuration
resource "aws_ssm_parameter" "app_config" {
  for_each = var.app_parameters

  name        = "/${var.environment}/app/${each.key}"
  description = "Application parameter: ${each.key}"
  type        = each.value.type
  value       = each.value.value

  tags = merge(var.common_tags, {
    Name = "${var.environment}-app-${each.key}"
  })
}