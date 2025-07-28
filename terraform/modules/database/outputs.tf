# Database Module Outputs

output "cluster_identifier" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.aurora.cluster_identifier
}

output "cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = aws_rds_cluster.aurora.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = aws_rds_cluster.aurora.port
}

output "cluster_database_name" {
  description = "Aurora cluster database name"
  value       = aws_rds_cluster.aurora.database_name
}

output "cluster_master_username" {
  description = "Aurora cluster master username"
  value       = aws_rds_cluster.aurora.master_username
  sensitive   = true
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.aurora.arn
}

output "cluster_resource_id" {
  description = "Aurora cluster resource ID"
  value       = aws_rds_cluster.aurora.cluster_resource_id
}

output "writer_instance_identifier" {
  description = "Aurora writer instance identifier"
  value       = aws_rds_cluster_instance.aurora_writer.identifier
}

output "writer_instance_endpoint" {
  description = "Aurora writer instance endpoint"
  value       = aws_rds_cluster_instance.aurora_writer.endpoint
}

output "reader_instance_identifiers" {
  description = "Aurora reader instance identifiers"
  value       = aws_rds_cluster_instance.aurora_reader[*].identifier
}

output "reader_instance_endpoints" {
  description = "Aurora reader instance endpoints"
  value       = aws_rds_cluster_instance.aurora_reader[*].endpoint
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.aurora.name
}

output "cluster_parameter_group_name" {
  description = "Aurora cluster parameter group name"
  value       = aws_rds_cluster_parameter_group.aurora.name
}

output "db_parameter_group_name" {
  description = "Aurora DB parameter group name"
  value       = aws_db_parameter_group.aurora.name
}

# Connection string for applications
output "connection_string" {
  description = "Database connection string"
  value       = "mysql://${aws_rds_cluster.aurora.master_username}:${var.master_password}@${aws_rds_cluster.aurora.endpoint}:${aws_rds_cluster.aurora.port}/${aws_rds_cluster.aurora.database_name}"
  sensitive   = true
}