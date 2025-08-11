# Automated Cloud Infrastructure

A comprehensive DevOps project demonstrating automated end-to-end cloud infrastructure deployment using Terraform and CI/CD pipelines.

## Project Overview

This project implements a production-ready, highly available AWS infrastructure using Infrastructure as Code (Terraform) with automated CI/CD pipelines (GitHub Actions). It showcases modern DevOps practices including cloud architecture, automation, monitoring, and security best practices.

<!-- Validation trigger: Updated 2025-01-08 -->

## Architecture

The infrastructure deploys a three-tier web application architecture:

- **Public Tier**: Application Load Balancer and NAT Gateways
- **Private Web Tier**: Web servers in Auto Scaling Groups
- **Private App Tier**: Application servers in Auto Scaling Groups  
- **Private Data Tier**: Aurora MySQL cluster with Multi-AZ deployment

### Key Components

- **VPC**: Multi-AZ network with public and private subnets
- **Aurora MySQL**: Highly available database cluster
- **Auto Scaling Groups**: Scalable compute infrastructure
- **Application Load Balancer**: Traffic distribution and SSL termination
- **CloudFront CDN**: Global content delivery with S3 failover ⭐ **NEW**
- **CloudWatch**: Comprehensive monitoring and alerting
- **Parameter Store**: Secure credential management
- **S3**: Static content and backup storage

### 🚀 CloudFront Enhancement

This project now includes **enterprise-grade CloudFront CDN** with the following features:

- **🌐 Global Content Delivery**: Edge locations worldwide for faster load times
- **🔒 HTTPS-Only Access**: Automatic HTTP to HTTPS redirect with TLS 1.2+
- **🛡️ Enhanced Security**: Security headers policy (HSTS, CSP, X-Frame-Options)
- **⚡ Automatic Failover**: ALB primary origin with S3 static site failover
- **💰 Cost Optimized**: PriceClass_100 for sandbox budget compliance
- **🔐 Origin Access Control**: Secure S3 access via OAC

**📖 See [CLOUDFRONT_ENHANCEMENT.md](CLOUDFRONT_ENHANCEMENT.md) for detailed implementation guide.**

## Project Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, gateways
│   ├── security/              # Security groups, IAM roles
│   ├── compute/               # EC2, ASG, Launch Templates
│   ├── database/              # Aurora cluster
│   ├── storage/               # S3 buckets
│   └── monitoring/            # CloudWatch, SNS, alarms
├── environments/              # Environment-specific configurations
│   ├── dev/                   # Development environment
│   └── prod/                  # Production environment
└── shared/                    # Shared configurations
    ├── backend.tf             # Remote state configuration
    └── providers.tf           # AWS provider configuration
```

## Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured with appropriate credentials
- **Git** for version control
- **GitHub account** for CI/CD pipelines

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd automated-cloud-infrastructure
```

### 2. Set Up Terraform Backend

First, create the S3 bucket and DynamoDB table for state management:

```bash
cd terraform/shared
terraform init
terraform plan
terraform apply
```

Note the S3 bucket name from the output for backend configuration.

### 3. Configure Backend for Environment

```bash
cd ../environments/dev
terraform init -backend-config="bucket=<your-terraform-state-bucket>"
```

### 4. Deploy Infrastructure

```bash
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Environment Configuration

### Development Environment
- **Instance Types**: t3.micro (cost-optimized)
- **Auto Scaling**: 1-2 instances
- **Database**: db.t3.medium with 7-day backup retention
- **Monitoring**: Basic CloudWatch monitoring

### Production Environment
- **Instance Types**: t3.small (performance-optimized)
- **Auto Scaling**: 2-8 instances
- **Database**: db.t3.medium with 30-day backup retention
- **Monitoring**: Enhanced monitoring with detailed metrics

## Security Features

- **Network Isolation**: Private subnets for application and database tiers
- **Security Groups**: Restrictive rules following least privilege principle
- **Encryption**: At-rest encryption for database and S3 buckets
- **Parameter Store**: Secure credential management
- **IAM Roles**: Least privilege access for EC2 instances

## Monitoring and Alerting

- **CloudWatch Dashboards**: Infrastructure and application metrics
- **CloudWatch Alarms**: CPU, memory, and database performance alerts
- **SNS Notifications**: Email and Slack integration for alerts
- **Enhanced Monitoring**: Detailed database performance insights

## CI/CD Pipeline

The project includes GitHub Actions workflows for:

- **Terraform Validation**: Format, validate, and security scanning
- **Infrastructure Planning**: Automated terraform plan on pull requests
- **Automated Deployment**: Terraform apply on main branch merges
- **Branch Protection**: Required reviews and status checks

## Cost Optimization

- **Right-sized Instances**: Environment-appropriate instance types
- **Auto Scaling**: Dynamic scaling based on demand
- **Resource Tagging**: Consistent tagging for cost tracking
- **Backup Optimization**: Environment-specific retention policies

## Disaster Recovery

- **Multi-AZ Deployment**: High availability across availability zones
- **Automated Backups**: Point-in-time recovery for Aurora
- **Infrastructure as Code**: Complete infrastructure recreation capability
- **Cross-region Replication**: Optional for critical data

## Contributing

1. Create a feature branch from `main`
2. Make your changes following the established patterns
3. Test your changes in the development environment
4. Submit a pull request with detailed description
5. Ensure all CI/CD checks pass before merging

## Troubleshooting

### Common Issues

1. **Backend Configuration**: Ensure S3 bucket and DynamoDB table exist
2. **AWS Credentials**: Verify AWS CLI configuration and permissions
3. **Resource Limits**: Check AWS service limits for your account
4. **State Locking**: Resolve any DynamoDB lock conflicts

### Support

For issues and questions:
- Check the troubleshooting section in documentation
- Review CloudWatch logs for infrastructure issues
- Consult AWS documentation for service-specific problems

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- AWS Well-Architected Framework for design principles
- Terraform best practices and community modules
- DevOps community for CI/CD pipeline patterns