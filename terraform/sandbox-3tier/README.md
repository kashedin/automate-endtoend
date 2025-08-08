# AWS Academy Sandbox 3-Tier Architecture

This Terraform configuration deploys a complete 3-tier web application architecture optimized for AWS Academy sandbox environments.

## 🎓 Sandbox Optimizations

This deployment is specifically designed to work within AWS Academy sandbox constraints:

### Instance Types
- **EC2 Instances**: `t3.micro` (sandbox compliant: t2/t3 nano to medium)
- **RDS Instance**: `db.t3.micro` (sandbox compliant: db.t3.micro to medium)

### Resource Limits
- **Max EC2 Instances**: 9 total (we use 4-6 instances)
- **Auto Scaling Groups**: Max 6 instances per ASG (we use 3 max per ASG)
- **RDS Storage**: Max 100GB (we use 20GB with 50GB max auto-scaling)

### IAM Compliance
- Uses existing `LabInstanceProfile` and `LabRole` as required
- No custom IAM roles created

### Cost Optimizations
- Single NAT Gateway instead of multiple
- Conservative scaling policies
- Single-AZ RDS deployment (no Multi-AZ)

## 🏗️ Architecture Components

### 1. Load Balancer Tier
- **Public Application Load Balancer**: Routes traffic to web tier
- **Internal Application Load Balancer**: Routes traffic within app tier

### 2. Web Tier (Private Subnets)
- **Auto Scaling Group**: 1-3 `t3.micro` instances
- **Apache HTTP Server**: Serves static content and proxies API requests
- **Health Checks**: ELB health checks with 30-second intervals

### 3. Application Tier (Private Subnets)
- **Auto Scaling Group**: 1-3 `t3.micro` instances
- **Node.js Application**: RESTful API with database connectivity
- **Internal Load Balancer**: High availability for app tier

### 4. Database Tier (Private Subnets)
- **RDS MySQL**: `db.t3.micro` instance
- **Storage**: 20GB with auto-scaling to 50GB
- **Backups**: 7-day retention period
- **Security**: Isolated in private subnets

### 5. Networking
- **VPC**: 10.0.0.0/16 CIDR block
- **Subnets**: Public, private web, private app, private database
- **NAT Gateway**: Single gateway for cost optimization
- **Security Groups**: Tier-specific access controls

## 🚀 Deployment

### Prerequisites
1. AWS Academy sandbox environment
2. GitHub repository with secrets configured:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`
   - `AWS_DEFAULT_REGION`

### Automatic Deployment
The deployment is triggered automatically when you push changes to:
- `terraform/sandbox-3tier/**`
- `.github/workflows/push-deploy-3tier.yml`

### Manual Deployment
```bash
cd terraform/sandbox-3tier
terraform init
terraform plan -var="environment=dev" -var="aws_region=us-west-2"
terraform apply
```

## 🔍 Testing the Deployment

### 1. Access the Application
Visit the Application URL provided in the deployment output.

### 2. Test Web Tier
- Main page loads with architecture overview
- Instance metadata displays correctly

### 3. Test Application Tier
- Click "Test App Tier Health" button
- Verify Node.js application responds

### 4. Test Database Tier
- Click "Test Database Connection" button
- Verify MySQL connectivity through app tier

### 5. Test Data Flow
- Click "Get App Data" button
- Verify end-to-end data retrieval

## 📊 Monitoring and Health Checks

### Application Health Endpoints
- **Web Tier**: `/health` - Apache server status
- **App Tier**: `/health` - Node.js application status
- **Database**: `/api/db-status` - MySQL connectivity

### Auto Scaling Triggers
- **CPU Utilization**: Scale out at 70%, scale in at 30%
- **Health Checks**: Unhealthy instances replaced automatically

## 🔧 Configuration

### Environment Variables
- `environment`: Deployment environment (default: "dev")
- `aws_region`: AWS region (default: "us-west-2")

### Scaling Configuration
```hcl
# Web Tier ASG
min_size         = 1
max_size         = 3
desired_capacity = 2

# App Tier ASG
min_size         = 1
max_size         = 3
desired_capacity = 2
```

### Database Configuration
```hcl
instance_class = "db.t3.micro"
allocated_storage = 20
max_allocated_storage = 50
storage_type = "gp2"
```

## 🛡️ Security Features

### Network Security
- **Private Subnets**: Web, app, and database tiers isolated
- **Security Groups**: Least-privilege access controls
- **NAT Gateway**: Secure outbound internet access

### Database Security
- **Private Subnets**: Database not accessible from internet
- **Security Groups**: Only app tier can access database
- **Encryption**: At-rest encryption (where supported in sandbox)

## 🧹 Cleanup

To destroy the infrastructure:
```bash
terraform destroy -var="environment=dev" -var="aws_region=us-west-2"
```

Or trigger the destroy action in GitHub Actions.

## 📝 Outputs

The deployment provides the following outputs:
- `application_url`: Public URL to access the application
- `vpc_id`: VPC identifier
- `database_endpoint`: RDS endpoint (sensitive)
- `app_internal_lb_dns`: Internal load balancer DNS
- Subnet IDs for all tiers

## 🎯 Learning Objectives

This deployment demonstrates:
1. **Multi-tier architecture design**
2. **AWS service integration**
3. **Infrastructure as Code with Terraform**
4. **Auto scaling and high availability**
5. **Security best practices**
6. **Load balancing strategies**
7. **Database connectivity patterns**
8. **CI/CD pipeline integration**

## 🔍 Troubleshooting

### Common Issues
1. **Instance limits**: Ensure total instances < 9
2. **Database connectivity**: Wait 5-10 minutes for RDS initialization
3. **Health checks**: Allow 2-3 minutes for health check stabilization
4. **NAT Gateway**: Single gateway may cause brief connectivity issues during updates

### Logs
- **Web Tier**: `/var/log/httpd/` and `/var/log/deployment.log`
- **App Tier**: `/var/log/app-server.log` and `/var/log/deployment.log`
- **System**: CloudWatch Logs (if enabled)

## 📚 Additional Resources

- [AWS Academy Learner Lab Guide](https://aws.amazon.com/training/awsacademy/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)