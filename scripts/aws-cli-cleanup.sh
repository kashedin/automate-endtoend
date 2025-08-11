#!/bin/bash

# AWS CLI Manual Cleanup Commands
# Direct AWS CLI commands to delete all infrastructure resources
# Use this when Terraform cleanup fails or for manual verification

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to confirm action
confirm_action() {
    local message=$1
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        echo ""
        read -p "$message (y/N): " confirmation
        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            print_color $YELLOW "Skipped by user"
            return 1
        fi
    fi
    return 0
}

# Default values
SKIP_CONFIRMATION=false
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes       Skip all confirmation prompts"
            echo "  --dry-run       Show commands without executing them"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_color $YELLOW "🧹 AWS CLI Manual Cleanup Commands"
print_color $YELLOW "=================================="

if [[ "$DRY_RUN" == "true" ]]; then
    print_color $CYAN "DRY RUN MODE - Commands will be displayed but not executed"
fi

# Function to execute or display command
execute_cmd() {
    local cmd=$1
    local description=$2
    
    print_color $CYAN "📋 $description"
    print_color $WHITE "Command: $cmd"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_color $YELLOW "  [DRY RUN] Command not executed"
        return 0
    fi
    
    if eval "$cmd"; then
        print_color $GREEN "  ✅ Success"
        return 0
    else
        print_color $RED "  ❌ Failed (may not exist)"
        return 1
    fi
}

print_color $RED "\n⚠️  WARNING: This will delete ALL infrastructure resources!"
print_color $YELLOW "This includes CloudFront, ALB, EC2, RDS, S3, VPC, and all data!"

if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
    echo ""
    read -p "Type 'DELETE ALL' to confirm complete resource destruction: " final_confirmation
    if [[ "$final_confirmation" != "DELETE ALL" ]]; then
        print_color $YELLOW "❌ Cleanup cancelled by user"
        exit 1
    fi
fi

print_color $GREEN "\n🚀 Starting AWS CLI cleanup..."

# =============================================================================
# 1. CLOUDFRONT DISTRIBUTIONS
# =============================================================================
print_color $YELLOW "\n📡 Step 1: CloudFront Distributions"

if confirm_action "Delete CloudFront distributions?"; then
    # List CloudFront distributions
    execute_cmd "aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,Comment:Comment,Status:Status}' --output table" "List CloudFront distributions"
    
    # Get distribution IDs (you'll need to replace with actual IDs)
    print_color $CYAN "Getting CloudFront distribution IDs..."
    DISTRIBUTION_IDS=$(aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].Id' --output text 2>/dev/null || echo "")
    
    if [[ -n "$DISTRIBUTION_IDS" ]]; then
        for dist_id in $DISTRIBUTION_IDS; do
            print_color $CYAN "Processing CloudFront distribution: $dist_id"
            
            # Get current config
            execute_cmd "aws cloudfront get-distribution-config --id $dist_id --query 'DistributionConfig' > /tmp/dist-config-$dist_id.json" "Get distribution config for $dist_id"
            
            # Disable distribution first
            execute_cmd "jq '.Enabled = false' /tmp/dist-config-$dist_id.json > /tmp/dist-config-disabled-$dist_id.json" "Prepare disabled config"
            
            # Update distribution to disabled
            ETAG=$(aws cloudfront get-distribution-config --id $dist_id --query 'ETag' --output text 2>/dev/null || echo "")
            if [[ -n "$ETAG" ]]; then
                execute_cmd "aws cloudfront update-distribution --id $dist_id --distribution-config file:///tmp/dist-config-disabled-$dist_id.json --if-match $ETAG" "Disable distribution $dist_id"
                
                print_color $YELLOW "  ⏳ Distribution $dist_id disabled. Waiting 5 minutes before deletion..."
                if [[ "$DRY_RUN" != "true" ]]; then
                    sleep 300  # Wait 5 minutes
                fi
                
                # Get new ETag after disable
                NEW_ETAG=$(aws cloudfront get-distribution-config --id $dist_id --query 'ETag' --output text 2>/dev/null || echo "")
                if [[ -n "$NEW_ETAG" ]]; then
                    execute_cmd "aws cloudfront delete-distribution --id $dist_id --if-match $NEW_ETAG" "Delete distribution $dist_id"
                fi
            fi
            
            # Cleanup temp files
            rm -f /tmp/dist-config-$dist_id.json /tmp/dist-config-disabled-$dist_id.json 2>/dev/null || true
        done
    else
        print_color $GREEN "  ✅ No CloudFront distributions found"
    fi
fi

# =============================================================================
# 2. APPLICATION LOAD BALANCERS
# =============================================================================
print_color $YELLOW "\n⚖️ Step 2: Application Load Balancers"

if confirm_action "Delete Application Load Balancers?"; then
    # List ALBs
    execute_cmd "aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, \`dev\`) || contains(LoadBalancerName, \`prod\`)].{Name:LoadBalancerName,Arn:LoadBalancerArn,State:State.Code}' --output table" "List Application Load Balancers"
    
    # Get ALB ARNs
    ALB_ARNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `dev`) || contains(LoadBalancerName, `prod`)].LoadBalancerArn' --output text 2>/dev/null || echo "")
    
    if [[ -n "$ALB_ARNS" ]]; then
        for alb_arn in $ALB_ARNS; do
            execute_cmd "aws elbv2 delete-load-balancer --load-balancer-arn $alb_arn" "Delete ALB: $alb_arn"
        done
    else
        print_color $GREEN "  ✅ No Application Load Balancers found"
    fi
fi

# =============================================================================
# 3. AUTO SCALING GROUPS
# =============================================================================
print_color $YELLOW "\n📈 Step 3: Auto Scaling Groups"

if confirm_action "Delete Auto Scaling Groups?"; then
    # List ASGs
    execute_cmd "aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, \`dev\`) || contains(AutoScalingGroupName, \`prod\`)].{Name:AutoScalingGroupName,Instances:length(Instances)}' --output table" "List Auto Scaling Groups"
    
    # Get ASG names
    ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `dev`) || contains(AutoScalingGroupName, `prod`)].AutoScalingGroupName' --output text 2>/dev/null || echo "")
    
    if [[ -n "$ASG_NAMES" ]]; then
        for asg_name in $ASG_NAMES; do
            # Set desired capacity to 0 first
            execute_cmd "aws autoscaling update-auto-scaling-group --auto-scaling-group-name $asg_name --desired-capacity 0 --min-size 0" "Scale down ASG: $asg_name"
            
            # Wait a bit for instances to terminate
            print_color $YELLOW "  ⏳ Waiting 30 seconds for instances to terminate..."
            if [[ "$DRY_RUN" != "true" ]]; then
                sleep 30
            fi
            
            # Delete ASG
            execute_cmd "aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $asg_name --force-delete" "Delete ASG: $asg_name"
        done
    else
        print_color $GREEN "  ✅ No Auto Scaling Groups found"
    fi
fi

# =============================================================================
# 4. EC2 INSTANCES
# =============================================================================
print_color $YELLOW "\n🖥️ Step 4: EC2 Instances"

if confirm_action "Terminate EC2 instances?"; then
    # List running instances
    execute_cmd "aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running,pending,stopping,stopped' --query 'Reservations[*].Instances[?Tags[?Key==\`Environment\` && (Value==\`dev\` || Value==\`prod\`)]].{InstanceId:InstanceId,Name:Tags[?Key==\`Name\`].Value|[0],State:State.Name}' --output table" "List EC2 instances"
    
    # Get instance IDs
    INSTANCE_IDS=$(aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running,pending,stopping,stopped' --query 'Reservations[*].Instances[?Tags[?Key==`Environment` && (Value==`dev` || Value==`prod`)]].InstanceId' --output text 2>/dev/null || echo "")
    
    if [[ -n "$INSTANCE_IDS" ]]; then
        execute_cmd "aws ec2 terminate-instances --instance-ids $INSTANCE_IDS" "Terminate instances: $INSTANCE_IDS"
    else
        print_color $GREEN "  ✅ No EC2 instances found"
    fi
fi

# =============================================================================
# 5. RDS DATABASES
# =============================================================================
print_color $YELLOW "\n🗄️ Step 5: RDS Databases"

if confirm_action "Delete RDS databases?"; then
    # List RDS instances
    execute_cmd "aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, \`dev\`) || contains(DBInstanceIdentifier, \`prod\`)].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine}' --output table" "List RDS instances"
    
    # Get DB instance identifiers
    DB_IDENTIFIERS=$(aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `dev`) || contains(DBInstanceIdentifier, `prod`)].DBInstanceIdentifier' --output text 2>/dev/null || echo "")
    
    if [[ -n "$DB_IDENTIFIERS" ]]; then
        for db_id in $DB_IDENTIFIERS; do
            execute_cmd "aws rds delete-db-instance --db-instance-identifier $db_id --skip-final-snapshot --delete-automated-backups" "Delete RDS instance: $db_id"
        done
    else
        print_color $GREEN "  ✅ No RDS instances found"
    fi
    
    # List and delete RDS clusters
    execute_cmd "aws rds describe-db-clusters --query 'DBClusters[?contains(DBClusterIdentifier, \`dev\`) || contains(DBClusterIdentifier, \`prod\`)].{Identifier:DBClusterIdentifier,Status:Status,Engine:Engine}' --output table" "List RDS clusters"
    
    CLUSTER_IDENTIFIERS=$(aws rds describe-db-clusters --query 'DBClusters[?contains(DBClusterIdentifier, `dev`) || contains(DBClusterIdentifier, `prod`)].DBClusterIdentifier' --output text 2>/dev/null || echo "")
    
    if [[ -n "$CLUSTER_IDENTIFIERS" ]]; then
        for cluster_id in $CLUSTER_IDENTIFIERS; do
            execute_cmd "aws rds delete-db-cluster --db-cluster-identifier $cluster_id --skip-final-snapshot" "Delete RDS cluster: $cluster_id"
        done
    else
        print_color $GREEN "  ✅ No RDS clusters found"
    fi
fi

# =============================================================================
# 6. S3 BUCKETS
# =============================================================================
print_color $YELLOW "\n🪣 Step 6: S3 Buckets"

if confirm_action "Delete S3 buckets and all contents?"; then
    # List S3 buckets
    execute_cmd "aws s3 ls | grep -E '(dev-|prod-)'" "List project S3 buckets"
    
    # Get bucket names
    BUCKET_NAMES=$(aws s3 ls | grep -E '(dev-|prod-)' | awk '{print $3}' 2>/dev/null || echo "")
    
    if [[ -n "$BUCKET_NAMES" ]]; then
        for bucket_name in $BUCKET_NAMES; do
            print_color $CYAN "Processing bucket: $bucket_name"
            
            # Remove all objects and versions
            execute_cmd "aws s3 rm s3://$bucket_name --recursive" "Empty bucket: $bucket_name"
            
            # Remove all object versions (if versioning enabled)
            execute_cmd "aws s3api delete-objects --bucket $bucket_name --delete \"\$(aws s3api list-object-versions --bucket $bucket_name --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)\" 2>/dev/null || true" "Delete object versions: $bucket_name"
            
            # Remove delete markers
            execute_cmd "aws s3api delete-objects --bucket $bucket_name --delete \"\$(aws s3api list-object-versions --bucket $bucket_name --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)\" 2>/dev/null || true" "Delete markers: $bucket_name"
            
            # Delete bucket
            execute_cmd "aws s3 rb s3://$bucket_name --force" "Delete bucket: $bucket_name"
        done
    else
        print_color $GREEN "  ✅ No project S3 buckets found"
    fi
fi

# =============================================================================
# 7. CLOUDWATCH RESOURCES
# =============================================================================
print_color $YELLOW "\n📊 Step 7: CloudWatch Resources"

if confirm_action "Delete CloudWatch log groups and alarms?"; then
    # Delete log groups
    execute_cmd "aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, \`dev\`) || contains(logGroupName, \`prod\`)].logGroupName' --output table" "List CloudWatch log groups"
    
    LOG_GROUPS=$(aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `dev`) || contains(logGroupName, `prod`)].logGroupName' --output text 2>/dev/null || echo "")
    
    if [[ -n "$LOG_GROUPS" ]]; then
        for log_group in $LOG_GROUPS; do
            execute_cmd "aws logs delete-log-group --log-group-name $log_group" "Delete log group: $log_group"
        done
    else
        print_color $GREEN "  ✅ No CloudWatch log groups found"
    fi
    
    # Delete alarms
    execute_cmd "aws cloudwatch describe-alarms --query 'MetricAlarms[?contains(AlarmName, \`dev\`) || contains(AlarmName, \`prod\`)].AlarmName' --output table" "List CloudWatch alarms"
    
    ALARM_NAMES=$(aws cloudwatch describe-alarms --query 'MetricAlarms[?contains(AlarmName, `dev`) || contains(AlarmName, `prod`)].AlarmName' --output text 2>/dev/null || echo "")
    
    if [[ -n "$ALARM_NAMES" ]]; then
        execute_cmd "aws cloudwatch delete-alarms --alarm-names $ALARM_NAMES" "Delete alarms: $ALARM_NAMES"
    else
        print_color $GREEN "  ✅ No CloudWatch alarms found"
    fi
fi

# =============================================================================
# 8. SNS TOPICS
# =============================================================================
print_color $YELLOW "\n📢 Step 8: SNS Topics"

if confirm_action "Delete SNS topics?"; then
    # List SNS topics
    execute_cmd "aws sns list-topics --query 'Topics[?contains(TopicArn, \`dev\`) || contains(TopicArn, \`prod\`)].TopicArn' --output table" "List SNS topics"
    
    TOPIC_ARNS=$(aws sns list-topics --query 'Topics[?contains(TopicArn, `dev`) || contains(TopicArn, `prod`)].TopicArn' --output text 2>/dev/null || echo "")
    
    if [[ -n "$TOPIC_ARNS" ]]; then
        for topic_arn in $TOPIC_ARNS; do
            execute_cmd "aws sns delete-topic --topic-arn $topic_arn" "Delete SNS topic: $topic_arn"
        done
    else
        print_color $GREEN "  ✅ No SNS topics found"
    fi
fi

# =============================================================================
# 9. VPC RESOURCES
# =============================================================================
print_color $YELLOW "\n🌐 Step 9: VPC Resources"

if confirm_action "Delete VPC and networking resources?"; then
    # Get VPC IDs
    VPC_IDS=$(aws ec2 describe-vpcs --filters 'Name=tag:Environment,Values=dev,prod' --query 'Vpcs[].VpcId' --output text 2>/dev/null || echo "")
    
    if [[ -n "$VPC_IDS" ]]; then
        for vpc_id in $VPC_IDS; do
            print_color $CYAN "Processing VPC: $vpc_id"
            
            # Delete NAT Gateways
            NAT_GATEWAY_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[?State==`available`].NatGatewayId' --output text 2>/dev/null || echo "")
            if [[ -n "$NAT_GATEWAY_IDS" ]]; then
                for nat_id in $NAT_GATEWAY_IDS; do
                    execute_cmd "aws ec2 delete-nat-gateway --nat-gateway-id $nat_id" "Delete NAT Gateway: $nat_id"
                done
                
                print_color $YELLOW "  ⏳ Waiting 60 seconds for NAT Gateways to delete..."
                if [[ "$DRY_RUN" != "true" ]]; then
                    sleep 60
                fi
            fi
            
            # Release Elastic IPs
            EIP_ALLOC_IDS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[?AssociationId==null].AllocationId' --output text 2>/dev/null || echo "")
            if [[ -n "$EIP_ALLOC_IDS" ]]; then
                for eip_id in $EIP_ALLOC_IDS; do
                    execute_cmd "aws ec2 release-address --allocation-id $eip_id" "Release Elastic IP: $eip_id"
                done
            fi
            
            # Delete Internet Gateway
            IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text 2>/dev/null || echo "")
            if [[ -n "$IGW_IDS" ]]; then
                for igw_id in $IGW_IDS; do
                    execute_cmd "aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id" "Detach Internet Gateway: $igw_id"
                    execute_cmd "aws ec2 delete-internet-gateway --internet-gateway-id $igw_id" "Delete Internet Gateway: $igw_id"
                done
            fi
            
            # Delete Subnets
            SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text 2>/dev/null || echo "")
            if [[ -n "$SUBNET_IDS" ]]; then
                for subnet_id in $SUBNET_IDS; do
                    execute_cmd "aws ec2 delete-subnet --subnet-id $subnet_id" "Delete Subnet: $subnet_id"
                done
            fi
            
            # Delete Route Tables (except main)
            ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" "Name=association.main,Values=false" --query 'RouteTables[].RouteTableId' --output text 2>/dev/null || echo "")
            if [[ -n "$ROUTE_TABLE_IDS" ]]; then
                for rt_id in $ROUTE_TABLE_IDS; do
                    execute_cmd "aws ec2 delete-route-table --route-table-id $rt_id" "Delete Route Table: $rt_id"
                done
            fi
            
            # Delete Security Groups (except default)
            SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null || echo "")
            if [[ -n "$SG_IDS" ]]; then
                for sg_id in $SG_IDS; do
                    execute_cmd "aws ec2 delete-security-group --group-id $sg_id" "Delete Security Group: $sg_id"
                done
            fi
            
            # Delete VPC
            execute_cmd "aws ec2 delete-vpc --vpc-id $vpc_id" "Delete VPC: $vpc_id"
        done
    else
        print_color $GREEN "  ✅ No project VPCs found"
    fi
fi

# =============================================================================
# FINAL VERIFICATION
# =============================================================================
print_color $YELLOW "\n🔍 Final Verification"

print_color $CYAN "Checking for remaining resources..."

# Check CloudFront
REMAINING_CF=$(aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].Id' --output text 2>/dev/null || echo "")
if [[ -n "$REMAINING_CF" ]]; then
    print_color $YELLOW "⚠️ CloudFront distributions still exist: $REMAINING_CF"
else
    print_color $GREEN "✅ No CloudFront distributions found"
fi

# Check EC2
REMAINING_EC2=$(aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running,pending,stopping,stopped' --query 'Reservations[*].Instances[?Tags[?Key==`Environment` && (Value==`dev` || Value==`prod`)]].InstanceId' --output text 2>/dev/null || echo "")
if [[ -n "$REMAINING_EC2" ]]; then
    print_color $YELLOW "⚠️ EC2 instances still exist: $REMAINING_EC2"
else
    print_color $GREEN "✅ No EC2 instances found"
fi

# Check S3
REMAINING_S3=$(aws s3 ls | grep -E '(dev-|prod-)' | awk '{print $3}' 2>/dev/null || echo "")
if [[ -n "$REMAINING_S3" ]]; then
    print_color $YELLOW "⚠️ S3 buckets still exist: $REMAINING_S3"
else
    print_color $GREEN "✅ No S3 buckets found"
fi

# Check RDS
REMAINING_RDS=$(aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `dev`) || contains(DBInstanceIdentifier, `prod`)].DBInstanceIdentifier' --output text 2>/dev/null || echo "")
if [[ -n "$REMAINING_RDS" ]]; then
    print_color $YELLOW "⚠️ RDS instances still exist: $REMAINING_RDS"
else
    print_color $GREEN "✅ No RDS instances found"
fi

print_color $GREEN "\n🎉 AWS CLI cleanup completed!"
print_color $YELLOW "📋 Summary:"
print_color $WHITE "- CloudFront distributions processed"
print_color $WHITE "- Load balancers deleted"
print_color $WHITE "- Auto Scaling Groups removed"
print_color $WHITE "- EC2 instances terminated"
print_color $WHITE "- RDS databases deleted"
print_color $WHITE "- S3 buckets emptied and removed"
print_color $WHITE "- CloudWatch resources cleaned"
print_color $WHITE "- SNS topics deleted"
print_color $WHITE "- VPC resources removed"

print_color $CYAN "\n💡 Next steps:"
print_color $WHITE "1. Wait 5-10 minutes for all deletions to complete"
print_color $WHITE "2. Check AWS Console to verify all resources are gone"
print_color $WHITE "3. Monitor for any remaining charges"
print_color $WHITE "4. Restart AWS Academy lab session if needed"

print_color $GREEN "\n✅ Cleanup process finished!"