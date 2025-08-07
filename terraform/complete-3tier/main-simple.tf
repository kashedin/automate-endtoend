# Simplified 3-Tier Architecture for AWS Academy Sandbox
# Uses default VPC to avoid VPC limits

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

variable "lab_role_name" {
  description = "Existing lab role name for EC2 instances"
  type        = string
  default     = "LabInstanceProfile"
}

# Random ID for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_iam_instance_profile" "lab_profile" {
  name = var.lab_role_name
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-${random_id.suffix.hex}-"
  vpc_id      = data.aws_vpc.default.id

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
  vpc_id      = data.aws_vpc.default.id

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
    cidr_blocks = [data.aws_vpc.default.cidr_block]
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
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from Web Tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description = "SSH for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
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

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-db-${random_id.suffix.hex}-"
  vpc_id      = data.aws_vpc.default.id

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
# APPLICATION LOAD BALANCER
# =============================================================================

resource "aws_lb" "main" {
  name               = "${var.environment}-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

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
  vpc_id   = data.aws_vpc.default.id

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

# Internal Load Balancer for App Tier
resource "aws_lb" "app_internal" {
  name               = "${var.environment}-app-int-${random_id.suffix.hex}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = data.aws_subnets.default.ids

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
  vpc_id   = data.aws_vpc.default.id

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
# DATABASE TIER (RDS MySQL)
# =============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-${random_id.suffix.hex}"
  subnet_ids = data.aws_subnets.default.ids

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

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-mysql-${random_id.suffix.hex}"

  # Engine settings
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  # Storage settings
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = false

  # Database settings
  db_name  = "appdb"
  username = "admin"
  password = "TempPassword123!"

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
# COMPUTE TIER (EC2 Auto Scaling)
# =============================================================================

# Launch Template for Web Tier
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-${random_id.suffix.hex}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data/web_user_data.sh", {
    app_server_url      = aws_lb.main.dns_name
    app_internal_lb_dns = aws_lb.app_internal.dns_name
    environment         = var.environment
  }))

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
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data/app_user_data.sh", {
    db_endpoint = aws_db_instance.main.endpoint
    db_name     = aws_db_instance.main.db_name
    db_username = aws_db_instance.main.username
    db_password = "TempPassword123!"
    environment = var.environment
  }))

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

# Auto Scaling Group for Web Tier
resource "aws_autoscaling_group" "web" {
  name                      = "${var.environment}-web-asg-${random_id.suffix.hex}"
  vpc_zone_identifier       = data.aws_subnets.default.ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

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

# Auto Scaling Group for App Tier
resource "aws_autoscaling_group" "app" {
  name                      = "${var.environment}-app-asg-${random_id.suffix.hex}"
  vpc_zone_identifier       = data.aws_subnets.default.ids
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

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
# OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
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