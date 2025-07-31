# Production Environment Values

aws_region = "us-west-2"
owner      = "devops-team"

# Networking Configuration
vpc_cidr                   = "10.0.0.0/16"
public_subnet_cidrs        = ["10.0.1.0/24", "10.0.2.0/24"]
private_web_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
private_app_subnet_cidrs   = ["10.0.20.0/24", "10.0.21.0/24"]
private_data_subnet_cidrs  = ["10.0.30.0/24", "10.0.31.0/24"]

# Environment-specific settings (production-grade with high availability)
environment_config = {
  name                = "prod"
  instance_type       = "t3.small"
  min_capacity        = 2
  max_capacity        = 8
  desired_capacity    = 3
  db_instance_class   = "db.t3.medium"
  backup_retention    = 30
  monitoring_enabled  = true
  cost_alerts_enabled = true
}

# Auto Scaling Group configurations
web_asg_config = {
  min_size         = 2
  max_size         = 8
  desired_capacity = 3
}

app_asg_config = {
  min_size         = 2
  max_size         = 6
  desired_capacity = 3
}

# Aurora configuration for production
aurora_config = {
  engine                        = "aurora-mysql"
  engine_version               = "8.0.mysql_aurora.3.04.0"
  instance_class               = "db.t3.medium"
  storage_encrypted            = true
  backup_retention_period      = 30
  backup_window               = "03:00-04:00"
  maintenance_window          = "sun:04:00-sun:05:00"
  monitoring_interval         = 60  # Enhanced monitoring enabled
  performance_insights_enabled = true
  deletion_protection         = true
  skip_final_snapshot         = false
  copy_tags_to_snapshot       = true
  reader_count                = 1  # One reader instance for HA
  auto_scaling_enabled        = true
  auto_scaling_min_capacity   = 1
  auto_scaling_max_capacity   = 3
  serverless_enabled          = false
  global_cluster_enabled      = false
}

# Alert email addresses for production monitoring
alert_email_addresses = [
  "devops-team@company.com",
  "platform-team@company.com"
]#
 ALB Configuration
enable_deletion_protection = true  # Enabled for production environment