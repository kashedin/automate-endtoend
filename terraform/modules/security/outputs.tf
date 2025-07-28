# Security Module Outputs

output "lab_role_arn" {
  description = "ARN of the existing lab role"
  value       = data.aws_iam_role.lab_role.arn
}

output "lab_role_name" {
  description = "Name of the existing lab role"
  value       = data.aws_iam_role.lab_role.name
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the Web tier security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the App tier security group"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "ID of the Database security group"
  value       = aws_security_group.database.id
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb      = aws_security_group.alb.id
    web      = aws_security_group.web.id
    app      = aws_security_group.app.id
    database = aws_security_group.database.id
  }
}

# Parameter Store outputs
output "db_username_parameter" {
  description = "Database username parameter name"
  value       = aws_ssm_parameter.db_username.name
}

output "db_password_parameter" {
  description = "Database password parameter name"
  value       = aws_ssm_parameter.db_password.name
  sensitive   = true
}

output "db_name_parameter" {
  description = "Database name parameter name"
  value       = aws_ssm_parameter.db_name.name
}

output "db_password_value" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}