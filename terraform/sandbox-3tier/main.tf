# AWS Academy Sandbox Optimized 3-Tier Architecture
# Designed to work within sandbox constraints

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
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# Random ID for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for template variables
locals {
  db_name     = "appdb"
  db_username = "admin"
  db_password = "TempPassword123!"
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use existing LabInstanceProfile as required by sandbox
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# =============================================================================
# NETWORKING LAYER (VPC and Subnets)
# =============================================================================

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "networking"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

# Public Subnets (for ALB and NAT Gateway)
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-${count.index + 1}-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "public"
  }
}

# Private Subnets - Web Tier
resource "aws_subnet" "private_web" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-private-web-${count.index + 1}-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "web"
  }
}

# Private Subnets - App Tier
resource "aws_subnet" "private_app" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-private-app-${count.index + 1}-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "app"
  }
}

# Private Subnets - Database Tier
resource "aws_subnet" "private_db" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 30}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-private-db-${count.index + 1}-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "database"
  }
}

# Single NAT Gateway for cost optimization (sandbox constraint)
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.environment}-nat-eip-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.environment}-nat-${random_id.suffix.hex}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-private-rt-${count.index + 1}-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_web" {
  count = 2

  subnet_id      = aws_subnet.private_web[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_app" {
  count = 2

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_db" {
  count = 2

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-${random_id.suffix.hex}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "load-balancer"
  }
}

# Web Tier Security Group
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-${random_id.suffix.hex}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "web"
  }
}

# App Tier Security Group
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-${random_id.suffix.hex}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from Web Tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description     = "HTTP from App Internal ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb.id]
  }

  ingress {
    description = "SSH for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-app-sg-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "app"
  }
}

# App Internal ALB Security Group
resource "aws_security_group" "app_alb" {
  name_prefix = "${var.environment}-app-alb-${random_id.suffix.hex}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from Web Tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-app-alb-sg-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "app-load-balancer"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-db-${random_id.suffix.hex}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from App Tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-db-sg-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "database"
  }
}

# =============================================================================
# APPLICATION LOAD BALANCERS
# =============================================================================

# Public ALB for Web Tier
resource "aws_lb" "main" {
  name               = "${var.environment}-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-alb-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "load-balancer"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg-${random_id.suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "${var.environment}-web-tg-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "web"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Internal ALB for App Tier
resource "aws_lb" "app_internal" {
  name               = "${var.environment}-app-int-${random_id.suffix.hex}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_alb.id]
  subnets            = aws_subnet.private_app[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-app-int-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "app-load-balancer"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.environment}-app-tg-${random_id.suffix.hex}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "${var.environment}-app-tg-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "app"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app_internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# =============================================================================
# DATABASE TIER (RDS MySQL) - Sandbox Optimized
# =============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-${random_id.suffix.hex}"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name        = "${var.environment}-db-subnet-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "database"
  }
}

resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "${var.environment}-db-params-${random_id.suffix.hex}"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  tags = {
    Name        = "${var.environment}-db-params-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

# RDS Instance optimized for sandbox constraints
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-mysql-${random_id.suffix.hex}"

  # Engine settings - sandbox compliant
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"  # Sandbox constraint: db.t3.micro to db.t3.medium

  # Storage settings - sandbox compliant
  allocated_storage     = 20   # Within 100GB limit
  max_allocated_storage = 50   # Within 100GB limit
  storage_type          = "gp2" # Sandbox allows gp2
  storage_encrypted     = false # KMS restrictions in sandbox

  # Database settings
  db_name  = local.db_name
  username = local.db_username
  password = local.db_password # In production, use AWS Secrets Manager

  # Network settings
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  # Backup settings
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name

  # Monitoring - disabled for sandbox
  monitoring_interval = 0

  # Availability - single AZ for sandbox (no Multi-AZ)
  multi_az = false

  # Deletion settings
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${var.environment}-mysql-${random_id.suffix.hex}"
    Environment = var.environment
    Tier        = "database"
  }
}

# =============================================================================
# COMPUTE TIER (EC2 Auto Scaling) - Sandbox Optimized
# =============================================================================

# Launch Template for Web Tier
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-${random_id.suffix.hex}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"  # Sandbox constraint: t2/t3 nano to medium

  vpc_security_group_ids = [aws_security_group.web.id]

  # Use required LabInstanceProfile
  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Tier - ${var.environment}</h1>" > /var/www/html/index.html
    echo "<p>Sandbox-optimized 3-tier architecture</p>" >> /var/www/html/index.html
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-server-${random_id.suffix.hex}"
      Environment = var.environment
      Tier        = "web"
    }
  }

  tags = {
    Name        = "${var.environment}-web-lt-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

# Launch Template for App Tier
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-${random_id.suffix.hex}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"  # Sandbox constraint: t2/t3 nano to medium

  vpc_security_group_ids = [aws_security_group.app.id]

  # Use required LabInstanceProfile
  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    curl -sL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
    mkdir -p /opt/app
    cd /opt/app
    echo '{"name":"app","version":"1.0.0","main":"server.js","dependencies":{"express":"^4.18.2"}}' > package.json
    npm install
    cat > server.js << 'APPEOF'
    const express = require('express');
    const app = express();
    app.get('/health', (req, res) => res.json({status: 'healthy', tier: 'app', env: '${var.environment}'}));
    app.listen(8080, () => console.log('App server running on port 8080'));
    APPEOF
    node server.js &
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-app-server-${random_id.suffix.hex}"
      Environment = var.environment
      Tier        = "app"
    }
  }

  tags = {
    Name        = "${var.environment}-app-lt-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

# Auto Scaling Group for Web Tier - Sandbox Optimized
resource "aws_autoscaling_group" "web" {
  name                      = "${var.environment}-web-asg-${random_id.suffix.hex}"
  vpc_zone_identifier       = aws_subnet.private_web[*].id
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Sandbox constraint: max 6 instances per ASG, max 9 total instances
  min_size         = 1
  max_size         = 3  # Conservative to stay within limits
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-web-asg-${random_id.suffix.hex}"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "web"
    propagate_at_launch = true
  }
}

# Auto Scaling Group for App Tier - Sandbox Optimized
resource "aws_autoscaling_group" "app" {
  name                      = "${var.environment}-app-asg-${random_id.suffix.hex}"
  vpc_zone_identifier       = aws_subnet.private_app[*].id
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Sandbox constraint: max 6 instances per ASG, max 9 total instances
  min_size         = 1
  max_size         = 3  # Conservative to stay within limits
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-app-asg-${random_id.suffix.hex}"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "app"
    propagate_at_launch = true
  }
}

# =============================================================================
# STORAGE MODULE (S3 Buckets)
# =============================================================================

module "storage" {
  source = "../modules/storage"

  environment                   = var.environment
  force_destroy_buckets        = true  # For sandbox environment
  log_retention_days           = 30    # Reduced for sandbox
  backup_retention_days        = 90    # Reduced for sandbox
  enable_cross_region_replication = false
  cloudfront_distribution_arn  = module.cdn.cloudfront_distribution_arn

  bucket_config = {
    versioning_enabled   = true
    encryption_enabled   = false  # Simplified for sandbox
    public_read_enabled  = false
    lifecycle_enabled    = true
    logging_enabled      = true
    enable_notifications = false
    destination_bucket   = ""
  }

  common_tags = {
    Environment = var.environment
    Project     = "3tier-architecture"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# CDN MODULE (CloudFront)
# =============================================================================

module "cdn" {
  source = "../modules/cdn"

  project_name              = "${var.environment}-3tier-${random_id.suffix.hex}"
  alb_dns_name             = aws_lb.main.dns_name
  s3_bucket_domain_name    = module.storage.static_website_bucket_regional_domain_name
  price_class              = "PriceClass_100"  # Cost-optimized for sandbox

  tags = {
    Environment = var.environment
    Project     = "3tier-architecture"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "application_url" {
  description = "URL of the application load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "app_internal_lb_dns" {
  description = "DNS name of the internal app tier load balancer"
  value       = aws_lb.app_internal.dns_name
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_web_subnets" {
  description = "IDs of the private web subnets"
  value       = aws_subnet.private_web[*].id
}

output "private_app_subnets" {
  description = "IDs of the private app subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnets" {
  description = "IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

# CloudFront and S3 outputs
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.cloudfront_domain_name
}

output "cloudfront_https_url" {
  description = "HTTPS URL for the application via CloudFront"
  value       = module.cdn.cloudfront_https_url
}

output "s3_static_website_bucket" {
  description = "S3 static website bucket name"
  value       = module.storage.static_website_bucket_id
}

output "s3_static_website_url" {
  description = "S3 static website URL"
  value       = module.storage.static_website_url
}