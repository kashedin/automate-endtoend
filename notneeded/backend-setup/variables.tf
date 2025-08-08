# Variables for Terraform Backend Setup

variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "automated-cloud-infrastructure"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "kashedin"
}