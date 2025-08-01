# Production Environment Configuration

# Include shared provider and backend configuration
terraform {
  required_version = ">= 1.0"

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

  # Using local backend for AWS Academy sandbox
  # backend "s3" {}
}

# AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "automated-cloud-infrastructure"
      ManagedBy   = "terraform"
      Environment = "prod"
      Owner       = var.owner
    }
  }
}

# Local values for production environment
locals {
  environment = "prod"
  common_tags = {
    Environment = "prod"
    Project     = "automated-cloud-infrastructure"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  environment               = local.environment
  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_web_subnet_cidrs  = var.private_web_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  common_tags               = local.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  environment = local.environment
  vpc_id      = module.networking.vpc_id
  vpc_cidr    = var.vpc_cidr
  common_tags = local.common_tags
}

# Database Module
module "database" {
  source = "../../modules/database"

  environment        = local.environment
  private_subnet_ids = module.networking.private_data_subnet_ids
  security_group_id  = module.security.database_security_group_id
  master_password    = module.security.db_password_value
  aurora_config      = var.aurora_config
  common_tags        = local.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  environment                = local.environment
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  web_subnet_ids             = module.networking.private_web_subnet_ids
  app_subnet_ids             = module.networking.private_app_subnet_ids
  alb_security_group_id      = module.security.alb_security_group_id
  web_security_group_id      = module.security.web_security_group_id
  app_security_group_id      = module.security.app_security_group_id
  instance_profile_name      = module.security.instance_profile_name
  database_endpoint          = module.database.cluster_endpoint
  web_instance_type          = var.environment_config.instance_type
  app_instance_type          = var.environment_config.instance_type
  web_asg_config             = var.web_asg_config
  app_asg_config             = var.app_asg_config
  enable_deletion_protection = true # Enable deletion protection in prod
  common_tags                = local.common_tags
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  environment           = local.environment
  force_destroy_buckets = false # Protect buckets in prod
  log_retention_days    = 90
  backup_retention_days = 365
  common_tags           = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  environment               = local.environment
  alb_arn_suffix            = split("/", module.compute.alb_arn)[1]
  web_asg_name              = module.compute.web_asg_name
  app_asg_name              = module.compute.app_asg_name
  db_cluster_identifier     = module.database.cluster_identifier
  web_scale_up_policy_arn   = module.compute.web_scale_up_policy_arn
  web_scale_down_policy_arn = module.compute.web_scale_down_policy_arn
  app_scale_up_policy_arn   = module.compute.app_scale_up_policy_arn
  app_scale_down_policy_arn = module.compute.app_scale_down_policy_arn
  alert_email_addresses     = var.alert_email_addresses
  log_retention_days        = 90
  common_tags               = local.common_tags
}