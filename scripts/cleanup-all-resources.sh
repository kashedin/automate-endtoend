#!/bin/bash

# Complete Infrastructure Cleanup Script for AWS Academy Sandbox
# This script destroys all Terraform-managed resources to avoid charges and resource limits

set -e

# Default values
ENVIRONMENT="both"
FORCE=false
SKIP_CONFIRMATION=false

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV    Environment to cleanup (dev|prod|both) [default: both]"
    echo "  -f, --force             Skip destroy plan, force immediate destruction"
    echo "  -y, --yes               Skip all confirmation prompts"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Cleanup both environments with confirmations"
    echo "  $0 -e dev               # Cleanup only dev environment"
    echo "  $0 -e prod -f -y        # Force cleanup prod environment without prompts"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment parameter
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod|both)$ ]]; then
    print_color $RED "❌ Invalid environment: $ENVIRONMENT"
    print_color $YELLOW "Valid options: dev, prod, both"
    exit 1
fi

print_color $YELLOW "🧹 AWS Infrastructure Cleanup Script"
print_color $YELLOW "===================================="

# Function to cleanup a specific environment
cleanup_environment() {
    local env_name=$1
    
    print_color $RED "\n🔥 Cleaning up $env_name environment..."
    print_color $CYAN "Environment: $env_name"
    
    local env_path="terraform/environments/$env_name"
    
    if [[ ! -d "$env_path" ]]; then
        print_color $RED "❌ Environment path not found: $env_path"
        return 1
    fi
    
    # Change to environment directory
    pushd "$env_path" > /dev/null
    
    print_color $YELLOW "📋 Step 1: Terraform Init"
    if ! terraform init; then
        print_color $RED "❌ Terraform init failed"
        popd > /dev/null
        return 1
    fi
    
    print_color $YELLOW "📋 Step 2: Terraform Plan (Destroy)"
    if ! terraform plan -destroy -out=destroy.tfplan; then
        print_color $RED "❌ Terraform destroy plan failed"
        popd > /dev/null
        return 1
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        print_color $RED "\n⚠️  WARNING: This will destroy ALL resources in $env_name environment!"
        print_color $YELLOW "This includes:"
        print_color $WHITE "- CloudFront Distribution"
        print_color $WHITE "- Application Load Balancer"
        print_color $WHITE "- Auto Scaling Groups & EC2 Instances"
        print_color $WHITE "- RDS Aurora Database"
        print_color $WHITE "- S3 Buckets (with all content)"
        print_color $WHITE "- VPC and all networking components"
        print_color $WHITE "- CloudWatch Log Groups"
        print_color $WHITE "- SNS Topics and Alarms"
        
        echo ""
        read -p "Type 'DESTROY' to confirm destruction of $env_name environment: " confirmation
        if [[ "$confirmation" != "DESTROY" ]]; then
            print_color $YELLOW "❌ Cleanup cancelled by user"
            popd > /dev/null
            return 1
        fi
    fi
    
    print_color $YELLOW "📋 Step 3: Terraform Destroy"
    if [[ "$FORCE" == "true" ]]; then
        terraform destroy -auto-approve
    else
        terraform apply -auto-approve destroy.tfplan
    fi
    
    if [[ $? -eq 0 ]]; then
        print_color $GREEN "✅ Successfully destroyed $env_name environment"
        
        # Clean up plan file
        [[ -f "destroy.tfplan" ]] && rm -f destroy.tfplan
        
        popd > /dev/null
        return 0
    else
        print_color $RED "❌ Terraform destroy failed for $env_name"
        popd > /dev/null
        return 1
    fi
}

# Function to cleanup orphaned resources via AWS CLI
cleanup_orphaned_resources() {
    print_color $YELLOW "\n🔍 Checking for orphaned resources..."
    
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        print_color $YELLOW "⚠️  AWS CLI not found. Skipping orphaned resource cleanup."
        return
    fi
    
    print_color $YELLOW "🧹 Cleaning up potential orphaned resources..."
    
    # List CloudFront distributions
    print_color $CYAN "📡 Checking CloudFront distributions..."
    if distributions=$(aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].{Id:Id,Comment:Comment,Status:Status}' --output table 2>/dev/null); then
        if [[ -n "$distributions" ]]; then
            echo "$distributions"
            print_color $YELLOW "⚠️  Found CloudFront distributions. These may take time to delete automatically."
        fi
    else
        print_color $YELLOW "⚠️  Could not check CloudFront distributions"
    fi
    
    # List S3 buckets that might be left behind
    print_color $CYAN "🪣 Checking S3 buckets..."
    if buckets=$(aws s3 ls | grep -E "(dev-|prod-)" 2>/dev/null); then
        print_color $YELLOW "Found potentially related S3 buckets:"
        echo "$buckets" | while read -r line; do
            print_color $WHITE "  $line"
        done
        
        if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
            echo ""
            read -p "Delete these S3 buckets? (y/N): " cleanup_s3
            if [[ "$cleanup_s3" =~ ^[Yy]$ ]]; then
                echo "$buckets" | while read -r line; do
                    bucket_name=$(echo "$line" | awk '{print $NF}')
                    print_color $RED "🗑️  Deleting bucket: $bucket_name"
                    aws s3 rb "s3://$bucket_name" --force 2>/dev/null || true
                done
            fi
        fi
    else
        print_color $YELLOW "⚠️  Could not check S3 buckets or none found"
    fi
}

# Main execution
print_color $CYAN "Environment(s) to cleanup: $ENVIRONMENT"
print_color $CYAN "Force mode: $FORCE"
print_color $CYAN "Skip confirmation: $SKIP_CONFIRMATION"

success=true

# Cleanup based on environment parameter
case "$ENVIRONMENT" in
    "dev")
        cleanup_environment "dev" || success=false
        ;;
    "prod")
        cleanup_environment "prod" || success=false
        ;;
    "both")
        cleanup_environment "dev" || success=false
        cleanup_environment "prod" || success=false
        ;;
esac

# Cleanup orphaned resources
if [[ "$success" == "true" ]]; then
    cleanup_orphaned_resources
fi

# Final summary
echo ""
if [[ "$success" == "true" ]]; then
    print_color $GREEN "🎉 Cleanup completed successfully!"
    print_color $GREEN "✅ All Terraform-managed resources have been destroyed"
    print_color $GREEN "💰 This should prevent any ongoing AWS charges"
    print_color $GREEN "🔄 You can safely restart your AWS Academy lab session"
else
    print_color $RED "❌ Cleanup completed with errors"
    print_color $YELLOW "⚠️  Some resources may still exist and incur charges"
    print_color $YELLOW "🔍 Check the AWS Console manually for any remaining resources"
fi

print_color $YELLOW "\n📋 Cleanup Summary:"
print_color $WHITE "- Environment(s): $ENVIRONMENT"
print_color $(if [[ "$success" == "true" ]]; then echo $GREEN; else echo $RED; fi) "- Status: $(if [[ "$success" == "true" ]]; then echo 'SUCCESS'; else echo 'FAILED'; fi)"
print_color $WHITE "- Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

# Exit with appropriate code
if [[ "$success" == "true" ]]; then
    exit 0
else
    exit 1
fi