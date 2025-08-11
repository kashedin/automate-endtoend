# 🛠️ AWS CLI Cleanup Commands Reference

## Quick Command Reference

### 🚀 Run Complete Cleanup Scripts

```bash
# Bash (Linux/macOS)
./scripts/aws-cli-cleanup.sh

# PowerShell (Windows)
.\scripts\aws-cli-cleanup.ps1

# With options
./scripts/aws-cli-cleanup.sh --yes --dry-run
.\scripts\aws-cli-cleanup.ps1 -SkipConfirmation -DryRun
```

## 📋 Individual AWS CLI Commands

### 1. CloudFront Distributions

```bash
# List CloudFront distributions
aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,Comment:Comment,Status:Status}' --output table

# Get project-related distributions
aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].{Id:Id,Comment:Comment,Status:Status}' --output table

# Disable distribution (replace DISTRIBUTION_ID)
aws cloudfront get-distribution-config --id DISTRIBUTION_ID --query 'DistributionConfig' > dist-config.json
# Edit dist-config.json to set "Enabled": false
aws cloudfront update-distribution --id DISTRIBUTION_ID --distribution-config file://dist-config.json --if-match ETAG

# Delete distribution (after disabled and deployed)
aws cloudfront delete-distribution --id DISTRIBUTION_ID --if-match ETAG
```

### 2. Application Load Balancers

```bash
# List ALBs
aws elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,Arn:LoadBalancerArn,State:State.Code}' --output table

# List project ALBs
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `dev`) || contains(LoadBalancerName, `prod`)].{Name:LoadBalancerName,Arn:LoadBalancerArn}' --output table

# Delete ALB (replace ARN)
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/name/id
```

### 3. Auto Scaling Groups

```bash
# List Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].{Name:AutoScalingGroupName,Instances:length(Instances),Min:MinSize,Max:MaxSize,Desired:DesiredCapacity}' --output table

# List project ASGs
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `dev`) || contains(AutoScalingGroupName, `prod`)].AutoScalingGroupName' --output text

# Scale down ASG to 0
aws autoscaling update-auto-scaling-group --auto-scaling-group-name ASG_NAME --desired-capacity 0 --min-size 0

# Delete ASG
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ASG_NAME --force-delete
```

### 4. EC2 Instances

```bash
# List all instances
aws ec2 describe-instances --query 'Reservations[*].Instances[?State.Name!=`terminated`].{InstanceId:InstanceId,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' --output table

# List project instances
aws ec2 describe-instances --filters 'Name=tag:Environment,Values=dev,prod' --query 'Reservations[*].Instances[?State.Name!=`terminated`].{InstanceId:InstanceId,State:State.Name,Environment:Tags[?Key==`Environment`].Value|[0]}' --output table

# Terminate instances
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0 i-0987654321fedcba0
```

### 5. RDS Databases

```bash
# List RDS instances
aws rds describe-db-instances --query 'DBInstances[].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass}' --output table

# List project RDS instances
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `dev`) || contains(DBInstanceIdentifier, `prod`)].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus}' --output table

# Delete RDS instance (skip final snapshot)
aws rds delete-db-instance --db-instance-identifier mydb-instance --skip-final-snapshot --delete-automated-backups

# List RDS clusters
aws rds describe-db-clusters --query 'DBClusters[].{Identifier:DBClusterIdentifier,Status:Status,Engine:Engine}' --output table

# Delete RDS cluster
aws rds delete-db-cluster --db-cluster-identifier mydb-cluster --skip-final-snapshot
```

### 6. S3 Buckets

```bash
# List all S3 buckets
aws s3 ls

# List project buckets
aws s3 ls | grep -E "(dev-|prod-)"

# Empty bucket (remove all objects)
aws s3 rm s3://bucket-name --recursive

# Delete bucket
aws s3 rb s3://bucket-name --force

# Delete bucket with versioning
aws s3api delete-objects --bucket bucket-name --delete "$(aws s3api list-object-versions --bucket bucket-name --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
aws s3api delete-objects --bucket bucket-name --delete "$(aws s3api list-object-versions --bucket bucket-name --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
aws s3 rb s3://bucket-name
```

### 7. CloudWatch Resources

```bash
# List log groups
aws logs describe-log-groups --query 'logGroups[].{Name:logGroupName,Size:storedBytes,Retention:retentionInDays}' --output table

# List project log groups
aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `dev`) || contains(logGroupName, `prod`)].logGroupName' --output text

# Delete log group
aws logs delete-log-group --log-group-name /aws/ec2/dev/web/httpd/access

# List CloudWatch alarms
aws cloudwatch describe-alarms --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Reason:StateReason}' --output table

# Delete alarms
aws cloudwatch delete-alarms --alarm-names alarm1 alarm2 alarm3
```

### 8. SNS Topics

```bash
# List SNS topics
aws sns list-topics --query 'Topics[].TopicArn' --output table

# List project topics
aws sns list-topics --query 'Topics[?contains(TopicArn, `dev`) || contains(TopicArn, `prod`)].TopicArn' --output text

# Delete SNS topic
aws sns delete-topic --topic-arn arn:aws:sns:region:account:topic-name
```

### 9. VPC and Networking

```bash
# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[].{VpcId:VpcId,CidrBlock:CidrBlock,State:State,Name:Tags[?Key==`Name`].Value|[0]}' --output table

# List project VPCs
aws ec2 describe-vpcs --filters 'Name=tag:Environment,Values=dev,prod' --query 'Vpcs[].VpcId' --output text

# Delete VPC resources (in order)
# 1. Terminate instances in VPC
# 2. Delete NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-12345" --query 'NatGateways[].NatGatewayId' --output text
aws ec2 delete-nat-gateway --nat-gateway-id nat-12345

# 3. Release Elastic IPs
aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[].AllocationId' --output text
aws ec2 release-address --allocation-id eipalloc-12345

# 4. Delete Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-12345" --query 'InternetGateways[].InternetGatewayId' --output text
aws ec2 detach-internet-gateway --internet-gateway-id igw-12345 --vpc-id vpc-12345
aws ec2 delete-internet-gateway --internet-gateway-id igw-12345

# 5. Delete Subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345" --query 'Subnets[].SubnetId' --output text
aws ec2 delete-subnet --subnet-id subnet-12345

# 6. Delete Route Tables (except main)
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-12345" "Name=association.main,Values=false" --query 'RouteTables[].RouteTableId' --output text
aws ec2 delete-route-table --route-table-id rtb-12345

# 7. Delete Security Groups (except default)
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-12345" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text
aws ec2 delete-security-group --group-id sg-12345

# 8. Delete VPC
aws ec2 delete-vpc --vpc-id vpc-12345
```

## 🔍 Verification Commands

### Check for Remaining Resources

```bash
# CloudFront
aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].{Id:Id,Status:Status}' --output table

# EC2 Instances
aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running,pending,stopping,stopped' --query 'Reservations[*].Instances[?Tags[?Key==`Environment` && (Value==`dev` || Value==`prod`)]].{InstanceId:InstanceId,State:State.Name}' --output table

# RDS
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `dev`) || contains(DBInstanceIdentifier, `prod`)].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus}' --output table

# S3 Buckets
aws s3 ls | grep -E "(dev-|prod-)"

# Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `dev`) || contains(AutoScalingGroupName, `prod`)].{Name:AutoScalingGroupName,Instances:length(Instances)}' --output table

# Load Balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `dev`) || contains(LoadBalancerName, `prod`)].{Name:LoadBalancerName,State:State.Code}' --output table
```

## 🚨 Emergency Cleanup (One-Liners)

### Terminate All Project EC2 Instances
```bash
aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filters 'Name=tag:Environment,Values=dev,prod' 'Name=instance-state-name,Values=running,pending,stopped,stopping' --query 'Reservations[*].Instances[].InstanceId' --output text)
```

### Delete All Project S3 Buckets
```bash
aws s3 ls | grep -E "(dev-|prod-)" | awk '{print $3}' | xargs -I {} aws s3 rb s3://{} --force
```

### Delete All Project Auto Scaling Groups
```bash
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `dev`) || contains(AutoScalingGroupName, `prod`)].AutoScalingGroupName' --output text | xargs -n1 aws autoscaling delete-auto-scaling-group --force-delete --auto-scaling-group-name
```

### Delete All Project RDS Instances
```bash
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `dev`) || contains(DBInstanceIdentifier, `prod`)].DBInstanceIdentifier' --output text | xargs -n1 aws rds delete-db-instance --skip-final-snapshot --delete-automated-backups --db-instance-identifier
```

## 💡 Tips and Best Practices

### 1. Always Check Before Deleting
```bash
# Use --dry-run when available
aws ec2 terminate-instances --dry-run --instance-ids i-1234567890abcdef0

# Use queries to preview what will be deleted
aws ec2 describe-instances --filters 'Name=tag:Environment,Values=dev' --query 'Reservations[*].Instances[].InstanceId' --output text
```

### 2. Handle Dependencies
- Delete resources in the correct order (instances → ASGs → ALBs → VPC)
- Wait for resources to fully terminate before deleting dependencies
- CloudFront distributions must be disabled before deletion

### 3. Batch Operations
```bash
# Get multiple resource IDs and process them
INSTANCE_IDS=$(aws ec2 describe-instances --filters 'Name=tag:Environment,Values=dev' --query 'Reservations[*].Instances[].InstanceId' --output text)
aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
```

### 4. Error Handling
```bash
# Continue on errors
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0 || echo "Instance may not exist"

# Check if resource exists before deletion
if aws ec2 describe-instances --instance-ids i-1234567890abcdef0 &>/dev/null; then
    aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
fi
```

## 🎯 Quick Start

### Complete Cleanup in One Command
```bash
# Bash
./scripts/aws-cli-cleanup.sh --yes

# PowerShell
.\scripts\aws-cli-cleanup.ps1 -SkipConfirmation
```

### Dry Run First
```bash
# See what would be deleted without actually deleting
./scripts/aws-cli-cleanup.sh --dry-run
.\scripts\aws-cli-cleanup.ps1 -DryRun
```

---

**⚠️ Warning**: These commands will permanently delete resources and data. Always verify what you're deleting and ensure you have backups if needed.

**💡 Tip**: Use the complete cleanup scripts for safety and comprehensive resource removal. Manual commands are provided for troubleshooting and specific scenarios.