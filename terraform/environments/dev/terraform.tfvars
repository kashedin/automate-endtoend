# Development Environment Values

aws_region = "us-east-1"
owner      = "devops-team"

# Networking Configuration
vpc_cidr                   = "10.0.0.0/16"
public_subnet_cidrs        = ["10.0.1.0/24", "10.0.2.0/24"]
private_web_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
private_app_subnet_cidrs   = ["10.0.20.0/24", "10.0.21.0/24"]
private_data_subnet_cidrs  = ["10.0.30.0/24", "10.0.31.0/24"]

# Environment-specific settings (cost-optimized for development)
environment_config = {
  name                = "dev"
  instance_type       = "t3.micro"
  min_capacity        = 1
  max_capacity        = 2
  desired_capacity    = 1
  db_instance_class   = "db.t3.medium"
  backup_retention    = 7
  monitoring_enabled  = true
  cost_alerts_enabled = false
}

# Auto Scaling Group configurations
web_asg_config = {
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
}

app_asg_config = {
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
}

# Aurora configuration for development
aurora_config = {
  engine                        = "aurora-mysql"
  engine_version               = "8.0.mysql_aurora.3.04.0"
  instance_class               = "db.t3.medium"
  storage_encrypted            = true
  backup_retention_period      = 7
  backup_window               = "03:00-04:00"
  maintenance_window          = "sun:04:00-sun:05:00"
  monitoring_interval         = 0  # Disable enhanced monitoring for cost savings
  performance_insights_enabled = false  # Disable for cost savings
  deletion_protection         = false
  skip_final_snapshot         = true  # Skip final snapshot in dev
  copy_tags_to_snapshot       = true
  reader_count                = 0  # No reader instances in dev
  auto_scaling_enabled        = false
  auto_scaling_min_capacity   = 1
  auto_scaling_max_capacity   = 2
  serverless_enabled          = false
  global_cluster_enabled      = false
}

# Alert email addresses (empty for dev)
alert_email_addresses = []