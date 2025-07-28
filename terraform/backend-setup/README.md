# Terraform Backend Setup

This directory contains the Terraform configuration to create the backend infrastructure needed for the automated cloud infrastructure project.

## What This Creates

- **S3 Bucket**: For storing Terraform state files with versioning and encryption
- **DynamoDB Table**: For Terraform state locking to prevent concurrent modifications
- **IAM Policy**: For backend access permissions

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (>= 1.0)

## Usage

### 1. Initialize and Apply

```bash
cd terraform/backend-setup
terraform init
terraform plan
terraform apply
```

### 2. Note the Outputs

After applying, note the outputs for GitHub Secrets:

```bash
terraform output github_secrets
```

### 3. Update Backend Configuration

Use the bucket name in your main Terraform configurations:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-kashedin-XXXXXXXX"  # From output
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock-kashedin"
    encrypt        = true
  }
}
```

## Security Features

- **Bucket Encryption**: AES256 server-side encryption
- **Versioning**: Enabled for state file history
- **Public Access**: Completely blocked
- **State Locking**: DynamoDB prevents concurrent modifications

## Cleanup

To destroy the backend infrastructure (only do this when no longer needed):

```bash
terraform destroy
```

**Warning**: Only destroy this after all other Terraform configurations using this backend have been destroyed.