# Create Terraform Backend Infrastructure in us-west-2
# This script creates the S3 bucket and DynamoDB table needed for Terraform state

Write-Host "Creating Terraform Backend Infrastructure in us-west-2..." -ForegroundColor Green

# Set AWS region
$env:AWS_DEFAULT_REGION = "us-west-2"

# Navigate to backend setup directory
Push-Location terraform/backend-setup

try {
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    terraform init
    
    Write-Host "Planning backend infrastructure..." -ForegroundColor Yellow
    terraform plan -var="aws_region=us-west-2"
    
    Write-Host "Creating backend infrastructure..." -ForegroundColor Yellow
    terraform apply -auto-approve -var="aws_region=us-west-2"
    
    Write-Host "Backend infrastructure created successfully!" -ForegroundColor Green
    
    # Get outputs
    Write-Host "Backend Configuration:" -ForegroundColor Cyan
    terraform output
    
} catch {
    Write-Host "Error creating backend infrastructure: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

Write-Host "Backend setup complete. You can now deploy the main infrastructure." -ForegroundColor Green