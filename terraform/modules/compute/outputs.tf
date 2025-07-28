# Compute Module Outputs

# Launch Template outputs
output "web_launch_template_id" {
  description = "ID of the web tier launch template"
  value       = aws_launch_template.web.id
}

output "app_launch_template_id" {
  description = "ID of the app tier launch template"
  value       = aws_launch_template.app.id
}

# Auto Scaling Group outputs
output "web_asg_name" {
  description = "Name of the web tier Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "web_asg_arn" {
  description = "ARN of the web tier Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "app_asg_name" {
  description = "Name of the app tier Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "app_asg_arn" {
  description = "ARN of the app tier Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

# Application Load Balancer outputs
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_hosted_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

# Target Group outputs
output "web_target_group_arn" {
  description = "ARN of the web tier target group"
  value       = aws_lb_target_group.web.arn
}

output "web_target_group_name" {
  description = "Name of the web tier target group"
  value       = aws_lb_target_group.web.name
}

# Auto Scaling Policy outputs
output "web_scale_up_policy_arn" {
  description = "ARN of the web tier scale up policy"
  value       = aws_autoscaling_policy.web_scale_up.arn
}

output "web_scale_down_policy_arn" {
  description = "ARN of the web tier scale down policy"
  value       = aws_autoscaling_policy.web_scale_down.arn
}

output "app_scale_up_policy_arn" {
  description = "ARN of the app tier scale up policy"
  value       = aws_autoscaling_policy.app_scale_up.arn
}

output "app_scale_down_policy_arn" {
  description = "ARN of the app tier scale down policy"
  value       = aws_autoscaling_policy.app_scale_down.arn
}

# Application URL
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}