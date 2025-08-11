# AWS CLI Manual Cleanup Commands (PowerShell)
# Direct AWS CLI commands to delete all infrastructure resources
# Use this when Terraform cleanup fails or for manual verification

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help = $false
)

if ($Help) {
    Write-Host "Usage: .\aws-cli-cleanup.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -SkipConfirmation    Skip all confirmation prompts"
    Write-Host "  -DryRun             Show commands without executing them"
    Write-Host "  -Help               Show this help message"
    exit 0
}

Write-Host "AWS CLI Manual Cleanup Commands" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "DRY RUN MODE - Commands will be displayed but not executed" -ForegroundColor Cyan
}

# Function to confirm action
function Confirm-Action {
    param([string]$Message)
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "$Message (y/N)"
        return ($confirmation -eq "y" -or $confirmation -eq "Y")
    }
    return $true
}

# Function to execute or display command
function Execute-Command {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "Command: $Description" -ForegroundColor Cyan
    Write-Host "Executing: $Command" -ForegroundColor White
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Command not executed" -ForegroundColor Yellow
        return $true
    }
    
    try {
        $result = Invoke-Expression $Command
        Write-Host "  Success" -ForegroundColor Green
        if ($result) {
            Write-Host $result
        }
        return $true
    } catch {
        Write-Host "  Failed (may not exist): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "`nWARNING: This will delete ALL infrastructure resources!" -ForegroundColor Red
Write-Host "This includes CloudFront, ALB, EC2, RDS, S3, VPC, and all data!" -ForegroundColor Yellow

if (-not $SkipConfirmation) {
    $finalConfirmation = Read-Host "`nType 'DELETE ALL' to confirm complete resource destruction"
    if ($finalConfirmation -ne "DELETE ALL") {
        Write-Host "Cleanup cancelled by user" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`nStarting AWS CLI cleanup..." -ForegroundColor Green

# =============================================================================
# 1. CLOUDFRONT DISTRIBUTIONS
# =============================================================================
Write-Host "`nStep 1: CloudFront Distributions" -ForegroundColor Yellow

if (Confirm-Action "Delete CloudFront distributions?") {
    # List CloudFront distributions
    Execute-Command "aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,Comment:Comment,Status:Status}' --output table" "List CloudFront distributions"
    
    # Get distribution IDs
    Write-Host "Getting CloudFront distribution IDs..." -ForegroundColor Cyan
    try {
        $distributionIds = aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].Id' --output text 2>$null
        
        if ($distributionIds -and $distributionIds.Trim() -ne "") {
            $distIds = $distributionIds.Split("`t").Trim()
            foreach ($distId in $distIds) {
                if ($distId) {
                    Write-Host "Processing CloudFront distribution: $distId" -ForegroundColor Cyan
                    
                    # Get current config
                    Execute-Command "aws cloudfront get-distribution-config --id $distId --query 'DistributionConfig' > temp-dist-config-$distId.json" "Get distribution config for $distId"
                    
                    if (-not $DryRun) {
                        # Disable distribution first
                        $config = Get-Content "temp-dist-config-$distId.json" | ConvertFrom-Json
                        $config.Enabled = $false
                        $config | ConvertTo-Json -Depth 10 | Out-File "temp-dist-config-disabled-$distId.json"
                        
                        # Get ETag
                        $etag = aws cloudfront get-distribution-config --id $distId --query 'ETag' --output text 2>$null
                        if ($etag) {
                            Execute-Command "aws cloudfront update-distribution --id $distId --distribution-config file://temp-dist-config-disabled-$distId.json --if-match $etag" "Disable distribution $distId"
                            
                            Write-Host "  Distribution $distId disabled. Waiting 5 minutes before deletion..." -ForegroundColor Yellow
                            Start-Sleep -Seconds 300  # Wait 5 minutes
                            
                            # Get new ETag after disable
                            $newEtag = aws cloudfront get-distribution-config --id $distId --query 'ETag' --output text 2>$null
                            if ($newEtag) {
                                Execute-Command "aws cloudfront delete-distribution --id $distId --if-match $newEtag" "Delete distribution $distId"
                            }
                        }
                        
                        # Cleanup temp files
                        Remove-Item "temp-dist-config-$distId.json" -ErrorAction SilentlyContinue
                        Remove-Item "temp-dist-config-disabled-$distId.json" -ErrorAction SilentlyContinue
                    }
                }
            }
        } else {
            Write-Host "  No CloudFront distributions found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing CloudFront distributions: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 2. APPLICATION LOAD BALANCERS
# =============================================================================
Write-Host "`nStep 2: Application Load Balancers" -ForegroundColor Yellow

if (Confirm-Action "Delete Application Load Balancers?") {
    # List ALBs
    Execute-Command "aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, ``dev``) || contains(LoadBalancerName, ``prod``)].{Name:LoadBalancerName,Arn:LoadBalancerArn,State:State.Code}' --output table" "List Application Load Balancers"
    
    # Get ALB ARNs
    try {
        $albArns = aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `dev`) || contains(LoadBalancerName, `prod`)].LoadBalancerArn' --output text 2>$null
        
        if ($albArns -and $albArns.Trim() -ne "") {
            $arns = $albArns.Split("`t").Trim()
            foreach ($arn in $arns) {
                if ($arn) {
                    Execute-Command "aws elbv2 delete-load-balancer --load-balancer-arn $arn" "Delete ALB: $arn"
                }
            }
        } else {
            Write-Host "  No Application Load Balancers found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing ALBs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 3. AUTO SCALING GROUPS
# =============================================================================
Write-Host "`nStep 3: Auto Scaling Groups" -ForegroundColor Yellow

if (Confirm-Action "Delete Auto Scaling Groups?") {
    # List ASGs
    Execute-Command "aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, ``dev``) || contains(AutoScalingGroupName, ``prod``)].{Name:AutoScalingGroupName,Instances:length(Instances)}' --output table" "List Auto Scaling Groups"
    
    # Get ASG names
    try {
        $asgNames = aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `dev`) || contains(AutoScalingGroupName, `prod`)].AutoScalingGroupName' --output text 2>$null
        
        if ($asgNames -and $asgNames.Trim() -ne "") {
            $names = $asgNames.Split("`t").Trim()
            foreach ($name in $names) {
                if ($name) {
                    # Set desired capacity to 0 first
                    Execute-Command "aws autoscaling update-auto-scaling-group --auto-scaling-group-name $name --desired-capacity 0 --min-size 0" "Scale down ASG: $name"
                    
                    # Wait for instances to terminate
                    Write-Host "  Waiting 30 seconds for instances to terminate..." -ForegroundColor Yellow
                    if (-not $DryRun) {
                        Start-Sleep -Seconds 30
                    }
                    
                    # Delete ASG
                    Execute-Command "aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $name --force-delete" "Delete ASG: $name"
                }
            }
        } else {
            Write-Host "  No Auto Scaling Groups found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing ASGs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 4. EC2 INSTANCES
# =============================================================================
Write-Host "`nStep 4: EC2 Instances" -ForegroundColor Yellow

if (Confirm-Action "Terminate EC2 instances?") {
    # List running instances
    Execute-Command "aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running,pending,stopping,stopped' --query 'Reservations[*].Instances[?Tags[?Key==``Environment`` && (Value==``dev`` || Value==``prod``)]].{InstanceId:InstanceId,Name:Tags[?Key==``Name``].Value|[0],State:State.Name}' --output table" "List EC2 instances"
    
    # Get instance IDs
    try {
        $instanceIds = aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running,pending,stopping,stopped' --query 'Reservations[*].Instances[?Tags[?Key==`Environment` && (Value==`dev` || Value==`prod`)]].InstanceId' --output text 2>$null
        
        if ($instanceIds -and $instanceIds.Trim() -ne "") {
            Execute-Command "aws ec2 terminate-instances --instance-ids $instanceIds" "Terminate instances: $instanceIds"
        } else {
            Write-Host "  No EC2 instances found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing EC2 instances: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 5. RDS DATABASES
# =============================================================================
Write-Host "`nStep 5: RDS Databases" -ForegroundColor Yellow

if (Confirm-Action "Delete RDS databases?") {
    # List RDS instances
    Execute-Command "aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, ``dev``) || contains(DBInstanceIdentifier, ``prod``)].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine}' --output table" "List RDS instances"
    
    # Get DB instance identifiers
    try {
        $dbIdentifiers = aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `dev`) || contains(DBInstanceIdentifier, `prod`)].DBInstanceIdentifier' --output text 2>$null
        
        if ($dbIdentifiers -and $dbIdentifiers.Trim() -ne "") {
            $identifiers = $dbIdentifiers.Split("`t").Trim()
            foreach ($identifier in $identifiers) {
                if ($identifier) {
                    Execute-Command "aws rds delete-db-instance --db-instance-identifier $identifier --skip-final-snapshot --delete-automated-backups" "Delete RDS instance: $identifier"
                }
            }
        } else {
            Write-Host "  No RDS instances found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing RDS instances: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # List and delete RDS clusters
    Execute-Command "aws rds describe-db-clusters --query 'DBClusters[?contains(DBClusterIdentifier, ``dev``) || contains(DBClusterIdentifier, ``prod``)].{Identifier:DBClusterIdentifier,Status:Status,Engine:Engine}' --output table" "List RDS clusters"
    
    try {
        $clusterIdentifiers = aws rds describe-db-clusters --query 'DBClusters[?contains(DBClusterIdentifier, `dev`) || contains(DBClusterIdentifier, `prod`)].DBClusterIdentifier' --output text 2>$null
        
        if ($clusterIdentifiers -and $clusterIdentifiers.Trim() -ne "") {
            $clusters = $clusterIdentifiers.Split("`t").Trim()
            foreach ($cluster in $clusters) {
                if ($cluster) {
                    Execute-Command "aws rds delete-db-cluster --db-cluster-identifier $cluster --skip-final-snapshot" "Delete RDS cluster: $cluster"
                }
            }
        } else {
            Write-Host "  No RDS clusters found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing RDS clusters: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 6. S3 BUCKETS
# =============================================================================
Write-Host "`nStep 6: S3 Buckets" -ForegroundColor Yellow

if (Confirm-Action "Delete S3 buckets and all contents?") {
    # List S3 buckets
    Execute-Command "aws s3 ls | Select-String -Pattern '(dev-|prod-)'" "List project S3 buckets"
    
    # Get bucket names
    try {
        $s3Output = aws s3 ls 2>$null
        if ($s3Output) {
            $bucketNames = $s3Output | Select-String -Pattern "(dev-|prod-)" | ForEach-Object { ($_ -split '\s+')[-1] }
            
            if ($bucketNames) {
                foreach ($bucketName in $bucketNames) {
                    if ($bucketName) {
                        Write-Host "Processing bucket: $bucketName" -ForegroundColor Cyan
                        
                        # Remove all objects and versions
                        Execute-Command "aws s3 rm s3://$bucketName --recursive" "Empty bucket: $bucketName"
                        
                        # Delete bucket
                        Execute-Command "aws s3 rb s3://$bucketName --force" "Delete bucket: $bucketName"
                    }
                }
            } else {
                Write-Host "  No project S3 buckets found" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  Error processing S3 buckets: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 7. CLOUDWATCH RESOURCES
# =============================================================================
Write-Host "`nStep 7: CloudWatch Resources" -ForegroundColor Yellow

if (Confirm-Action "Delete CloudWatch log groups and alarms?") {
    # Delete log groups
    Execute-Command "aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, ``dev``) || contains(logGroupName, ``prod``)].logGroupName' --output table" "List CloudWatch log groups"
    
    try {
        $logGroups = aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `dev`) || contains(logGroupName, `prod`)].logGroupName' --output text 2>$null
        
        if ($logGroups -and $logGroups.Trim() -ne "") {
            $groups = $logGroups.Split("`t").Trim()
            foreach ($group in $groups) {
                if ($group) {
                    Execute-Command "aws logs delete-log-group --log-group-name $group" "Delete log group: $group"
                }
            }
        } else {
            Write-Host "  No CloudWatch log groups found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing CloudWatch log groups: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Delete alarms
    Execute-Command "aws cloudwatch describe-alarms --query 'MetricAlarms[?contains(AlarmName, ``dev``) || contains(AlarmName, ``prod``)].AlarmName' --output table" "List CloudWatch alarms"
    
    try {
        $alarmNames = aws cloudwatch describe-alarms --query 'MetricAlarms[?contains(AlarmName, `dev`) || contains(AlarmName, `prod`)].AlarmName' --output text 2>$null
        
        if ($alarmNames -and $alarmNames.Trim() -ne "") {
            Execute-Command "aws cloudwatch delete-alarms --alarm-names $alarmNames" "Delete alarms: $alarmNames"
        } else {
            Write-Host "  No CloudWatch alarms found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing CloudWatch alarms: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 8. SNS TOPICS
# =============================================================================
Write-Host "`nStep 8: SNS Topics" -ForegroundColor Yellow

if (Confirm-Action "Delete SNS topics?") {
    # List SNS topics
    Execute-Command "aws sns list-topics --query 'Topics[?contains(TopicArn, ``dev``) || contains(TopicArn, ``prod``)].TopicArn' --output table" "List SNS topics"
    
    try {
        $topicArns = aws sns list-topics --query 'Topics[?contains(TopicArn, `dev`) || contains(TopicArn, `prod`)].TopicArn' --output text 2>$null
        
        if ($topicArns -and $topicArns.Trim() -ne "") {
            $arns = $topicArns.Split("`t").Trim()
            foreach ($arn in $arns) {
                if ($arn) {
                    Execute-Command "aws sns delete-topic --topic-arn $arn" "Delete SNS topic: $arn"
                }
            }
        } else {
            Write-Host "  No SNS topics found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing SNS topics: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# 9. VPC AND NETWORKING RESOURCES
# =============================================================================
Write-Host "`nStep 9: VPC and Networking Resources" -ForegroundColor Yellow

if (Confirm-Action "Delete VPCs and all networking resources (excluding default VPC)?") {
    # List all VPCs (excluding default)
    Execute-Command "aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==``false``].{VpcId:VpcId,CidrBlock:CidrBlock,Tags:Tags[?Key==``Name``].Value|[0]}' --output table" "List custom VPCs"
    
    try {
        # Get custom VPC IDs (non-default VPCs)
        $vpcIds = aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].VpcId' --output text 2>$null
        
        if ($vpcIds -and $vpcIds.Trim() -ne "") {
            $vpcs = $vpcIds.Split("`t").Trim()
            foreach ($vpcId in $vpcs) {
                if ($vpcId) {
                    Write-Host "Processing VPC: $vpcId" -ForegroundColor Cyan
                    
                    # 1. Delete NAT Gateways first (they take time to delete)
                    Write-Host "  Deleting NAT Gateways in VPC: $vpcId" -ForegroundColor Cyan
                    try {
                        $natGateways = aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpcId" --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text 2>$null
                        if ($natGateways -and $natGateways.Trim() -ne "") {
                            $natGwIds = $natGateways.Split("`t").Trim()
                            foreach ($natGwId in $natGwIds) {
                                if ($natGwId) {
                                    Execute-Command "aws ec2 delete-nat-gateway --nat-gateway-id $natGwId" "Delete NAT Gateway: $natGwId"
                                }
                            }
                            # Wait for NAT Gateways to delete
                            Write-Host "  Waiting 60 seconds for NAT Gateways to delete..." -ForegroundColor Yellow
                            if (-not $DryRun) {
                                Start-Sleep -Seconds 60
                            }
                        }
                    } catch {
                        Write-Host "  Error processing NAT Gateways: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    # 2. Delete Internet Gateways
                    Write-Host "  Deleting Internet Gateways in VPC: $vpcId" -ForegroundColor Cyan
                    try {
                        $internetGateways = aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcId" --query 'InternetGateways[].InternetGatewayId' --output text 2>$null
                        if ($internetGateways -and $internetGateways.Trim() -ne "") {
                            $igwIds = $internetGateways.Split("`t").Trim()
                            foreach ($igwId in $igwIds) {
                                if ($igwId) {
                                    Execute-Command "aws ec2 detach-internet-gateway --internet-gateway-id $igwId --vpc-id $vpcId" "Detach Internet Gateway: $igwId from VPC: $vpcId"
                                    Execute-Command "aws ec2 delete-internet-gateway --internet-gateway-id $igwId" "Delete Internet Gateway: $igwId"
                                }
                            }
                        }
                    } catch {
                        Write-Host "  Error processing Internet Gateways: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    # 3. Delete VPC Endpoints
                    Write-Host "  Deleting VPC Endpoints in VPC: $vpcId" -ForegroundColor Cyan
                    try {
                        $vpcEndpoints = aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpcId" --query 'VpcEndpoints[].VpcEndpointId' --output text 2>$null
                        if ($vpcEndpoints -and $vpcEndpoints.Trim() -ne "") {
                            $endpointIds = $vpcEndpoints.Split("`t").Trim()
                            foreach ($endpointId in $endpointIds) {
                                if ($endpointId) {
                                    Execute-Command "aws ec2 delete-vpc-endpoint --vpc-endpoint-id $endpointId" "Delete VPC Endpoint: $endpointId"
                                }
                            }
                        }
                    } catch {
                        Write-Host "  Error processing VPC Endpoints: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    # 4. Delete Security Groups (except default)
                    Write-Host "  Deleting Security Groups in VPC: $vpcId" -ForegroundColor Cyan
                    try {
                        $securityGroups = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>$null
                        if ($securityGroups -and $securityGroups.Trim() -ne "") {
                            $sgIds = $securityGroups.Split("`t").Trim()
                            foreach ($sgId in $sgIds) {
                                if ($sgId) {
                                    Execute-Command "aws ec2 delete-security-group --group-id $sgId" "Delete Security Group: $sgId"
                                }
                            }
                        }
                    } catch {
                        Write-Host "  Error processing Security Groups: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    # 5. Delete Network ACLs (except default)
                    Write-Host "  Deleting Network ACLs in VPC: $vpcId" -ForegroundColor Cyan
                    try {
                        $networkAcls = aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$vpcId" --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' --output text 2>$null
                        if ($networkAcls -and $networkAcls.Trim() -ne "") {
                            $aclIds = $networkAcls.Split("`t").Trim()
                            foreach ($aclId in $aclIds) {
                                if ($aclId) {
                                    Execute-Command "aws ec2 delete-network-acl --network-acl-id $aclId" "Delete Network ACL: $aclId"
                                }
                            }
                        }
                    } catch {
                        Write-Host "  Error processing Network ACLs: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    # 6. Delete Route Tables (except main route table)
                    Write-Host "  Deleting Route Tables in VPC: $vpcId" -ForegroundColor Cyan
                    try {
                        $routeTables = aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcId" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text 2>$null
                        if ($routeTables -and $routeTables.Trim() -ne "") {
                            $rtIds = $routeTables.Split("`t").Trim()
                            foreach ($rtId in $rtIds) {
                                if ($rtId) {
                                    Execute-Command "aws ec2 delete-route-table --route-table-id $rtId" "Delete Route Table: $rtId"
                                }
                            }
                        }
                    } catch {
                        Write-Host "  Error processing Route Tables: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    # 7. Delete Subnets
                    Write-Host "  Deleting Subnets in VPC: $vpcId" -ForegroundColor Cyan
                    try {
                        $subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" --query 'Subnets[].SubnetId' --output text 2>$null
                        if ($subnets -and $subnets.Trim() -ne "") {
                            $subnetIds = $subnets.Split("`t").Trim()
                            foreach ($subnetId in $subnetIds) {
                                if ($subnetId) {
                                    Execute-Command "aws ec2 delete-subnet --subnet-id $subnetId" "Delete Subnet: $subnetId"
                                }
                            }
                        }
                    } catch {
                        Write-Host "  Error processing Subnets: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    # 8. Finally, delete the VPC
                    Write-Host "  Deleting VPC: $vpcId" -ForegroundColor Cyan
                    Execute-Command "aws ec2 delete-vpc --vpc-id $vpcId" "Delete VPC: $vpcId"
                }
            }
        } else {
            Write-Host "  No custom VPCs found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing VPCs: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Clean up any remaining Elastic IPs
    Write-Host "  Releasing unassociated Elastic IPs..." -ForegroundColor Cyan
    try {
        $elasticIps = aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text 2>$null
        if ($elasticIps -and $elasticIps.Trim() -ne "") {
            $eipIds = $elasticIps.Split("`t").Trim()
            foreach ($eipId in $eipIds) {
                if ($eipId) {
                    Execute-Command "aws ec2 release-address --allocation-id $eipId" "Release Elastic IP: $eipId"
                }
            }
        } else {
            Write-Host "  No unassociated Elastic IPs found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing Elastic IPs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# FINAL VERIFICATION
# =============================================================================
Write-Host "`nFinal Verification" -ForegroundColor Yellow

Write-Host "Checking for remaining resources..." -ForegroundColor Cyan

# Check CloudFront
try {
    $remainingCF = aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].Id' --output text 2>$null
    if ($remainingCF -and $remainingCF.Trim() -ne "") {
        Write-Host "WARNING: CloudFront distributions still exist: $remainingCF" -ForegroundColor Yellow
    } else {
        Write-Host "SUCCESS: No CloudFront distributions found" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Could not check CloudFront distributions" -ForegroundColor Yellow
}

# Check EC2
try {
    $remainingEC2 = aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running,pending,stopping,stopped' --query 'Reservations[*].Instances[?Tags[?Key==`Environment` && (Value==`dev` || Value==`prod`)]].InstanceId' --output text 2>$null
    if ($remainingEC2 -and $remainingEC2.Trim() -ne "") {
        Write-Host "WARNING: EC2 instances still exist: $remainingEC2" -ForegroundColor Yellow
    } else {
        Write-Host "SUCCESS: No EC2 instances found" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Could not check EC2 instances" -ForegroundColor Yellow
}

# Check S3
try {
    $s3Output = aws s3 ls 2>$null
    if ($s3Output) {
        $remainingS3 = $s3Output | Select-String -Pattern "(dev-|prod-)" | ForEach-Object { ($_ -split '\s+')[-1] }
        if ($remainingS3) {
            Write-Host "WARNING: S3 buckets still exist: $($remainingS3 -join ', ')" -ForegroundColor Yellow
        } else {
            Write-Host "SUCCESS: No S3 buckets found" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "WARNING: Could not check S3 buckets" -ForegroundColor Yellow
}

# Check RDS
try {
    $remainingRDS = aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `dev`) || contains(DBInstanceIdentifier, `prod`)].DBInstanceIdentifier' --output text 2>$null
    if ($remainingRDS -and $remainingRDS.Trim() -ne "") {
        Write-Host "WARNING: RDS instances still exist: $remainingRDS" -ForegroundColor Yellow
    } else {
        Write-Host "SUCCESS: No RDS instances found" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Could not check RDS instances" -ForegroundColor Yellow
}

# Check VPCs
try {
    $remainingVPCs = aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].VpcId' --output text 2>$null
    if ($remainingVPCs -and $remainingVPCs.Trim() -ne "") {
        Write-Host "WARNING: Custom VPCs still exist: $remainingVPCs" -ForegroundColor Yellow
    } else {
        Write-Host "SUCCESS: No custom VPCs found" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Could not check VPCs" -ForegroundColor Yellow
}

Write-Host "`nAWS CLI cleanup completed!" -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- CloudFront distributions processed" -ForegroundColor White
Write-Host "- Load balancers deleted" -ForegroundColor White
Write-Host "- Auto Scaling Groups removed" -ForegroundColor White
Write-Host "- EC2 instances terminated" -ForegroundColor White
Write-Host "- RDS databases deleted" -ForegroundColor White
Write-Host "- S3 buckets emptied and removed" -ForegroundColor White
Write-Host "- CloudWatch resources cleaned" -ForegroundColor White
Write-Host "- SNS topics deleted" -ForegroundColor White
Write-Host "- VPCs and networking resources deleted" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Wait 5-10 minutes for all deletions to complete" -ForegroundColor White
Write-Host "2. Check AWS Console to verify all resources are gone" -ForegroundColor White
Write-Host "3. Monitor for any remaining charges" -ForegroundColor White
Write-Host "4. Restart AWS Academy lab session if needed" -ForegroundColor White

Write-Host "`nCleanup process finished!" -ForegroundColor Green