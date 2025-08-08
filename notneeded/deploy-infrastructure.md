# Deploy Infrastructure to AWS

## ⚠️ Important Notes

**This will create real AWS resources and may incur costs!**

Estimated monthly cost for development environment: $50-100
- RDS Aurora: ~$30-50/month
- EC2 instances: ~$20-30/month  
- Load Balancer: ~$15/month
- Other services: ~$5-10/month

## Deployment Steps

### Step 1: Run Terraform Plan First
Always run a plan before applying:

```bash
# Via GitHub Actions
1. Go to: https://github.com/kashedin/automate-endtoend/actions
2. Click "Terraform Plan" 
3. Run for "development" environment
4. Review the plan output carefully
```

### Step 2: Deploy Infrastructure

```bash
# Via GitHub Actions
1. Go to: https://github.com/kashedin/automate-endtoend/actions
2. Click "Terraform Apply"
3. Select environment: "development"
4. Click "Run workflow"
5. Monitor the deployment progress
```

### Step 3: Verify Deployment

After successful deployment, verify in AWS Console:

#### VPC and Networking
- Go to VPC Console
- Verify VPC created with correct CIDR
- Check subnets, route tables, gateways

#### EC2 and Load Balancing
- Go to EC2 Console
- Check Auto Scaling Groups are created
- Verify instances are launching
- Check Load Balancer and target groups

#### RDS Database
- Go to RDS Console
- Verify Aurora cluster is available
- Check cluster endpoints

#### S3 Storage
- Go to S3 Console
- Verify bucket created with static content

#### CloudWatch Monitoring
- Go to CloudWatch Console
- Check alarms are created
- Verify log groups exist

## Expected Deployment Time

- **Total time**: 15-25 minutes
- **VPC/Networking**: 2-3 minutes
- **RDS Aurora**: 10-15 minutes (longest component)
- **EC2/Auto Scaling**: 3-5 minutes
- **Load Balancer**: 2-3 minutes
- **Monitoring setup**: 1-2 minutes

## Testing the Deployed Infrastructure

### 1. Test Load Balancer
```bash
# Get load balancer DNS name from AWS Console
curl http://your-load-balancer-dns-name
```

### 2. Test Database Connectivity
```bash
# From an EC2 instance in the private subnet
mysql -h your-aurora-endpoint -u admin -p
```

### 3. Test Auto Scaling
- Terminate an instance manually
- Verify Auto Scaling Group launches replacement

### 4. Test Monitoring
- Check CloudWatch metrics
- Verify alarms trigger appropriately

## Cleanup (Important!)

To avoid ongoing costs, destroy resources when testing is complete:

```bash
# Via GitHub Actions
1. Go to Actions → "Terraform Destroy" (if available)
2. Or manually via CLI:

cd terraform/environments/dev
terraform init -backend-config="bucket=terraform-state-kashedin-422bf0c7" \
               -backend-config="key=dev/terraform.tfstate" \
               -backend-config="region=us-west-2" \
               -backend-config="dynamodb_table=terraform-state-lock-kashedin"
terraform destroy
```

## Troubleshooting Common Issues

### 1. RDS Creation Fails
- Check if Aurora is available in your region
- Verify subnet group has subnets in different AZs

### 2. EC2 Instances Fail to Launch
- Check if AMI is available in your region
- Verify security groups allow necessary traffic

### 3. Load Balancer Health Checks Fail
- Verify target group configuration
- Check security group rules
- Ensure application is running on correct port

### 4. State Locking Issues
- Verify DynamoDB table exists and is accessible
- Check AWS credentials have DynamoDB permissions

## Success Criteria

Deployment is successful when:
- ✅ All Terraform resources created without errors
- ✅ EC2 instances are running and healthy
- ✅ Load balancer passes health checks
- ✅ RDS cluster is available
- ✅ CloudWatch alarms are active
- ✅ Application is accessible via load balancer

## Production Deployment

For production deployment:
1. Complete development testing first
2. Review production configuration in `terraform/environments/prod/`
3. Run plan for production environment
4. Ensure production environment protection rules are active
5. Get required approvals before applying

Your infrastructure is now ready for production workloads! 🚀