# Networking Module

This Terraform module creates a comprehensive AWS networking infrastructure with VPC, subnets, NAT gateways, and routing for a three-tier application architecture.

## Architecture

The module creates:

- **VPC**: Single VPC with configurable CIDR block
- **Public Subnets**: For Application Load Balancer and NAT Gateways
- **Private Subnets**: Separated into three tiers (Web, App, Data)
- **Internet Gateway**: For public internet access
- **NAT Gateways**: High availability NAT gateways in each AZ
- **Route Tables**: Proper routing for public and private subnets

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  environment                = "dev"
  vpc_cidr                   = "10.0.0.0/16"
  public_subnet_cidrs        = ["10.0.1.0/24", "10.0.2.0/24"]
  private_web_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
  private_app_subnet_cidrs   = ["10.0.20.0/24", "10.0.21.0/24"]
  private_data_subnet_cidrs  = ["10.0.30.0/24", "10.0.31.0/24"]
  
  common_tags = {
    Environment = "dev"
    Project     = "automated-cloud-infrastructure"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_web_subnet_cidrs | CIDR blocks for private web tier subnets | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]` | no |
| private_app_subnet_cidrs | CIDR blocks for private app tier subnets | `list(string)` | `["10.0.20.0/24", "10.0.21.0/24"]` | no |
| private_data_subnet_cidrs | CIDR blocks for private data tier subnets | `list(string)` | `["10.0.30.0/24", "10.0.31.0/24"]` | no |
| common_tags | Common tags to be applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| internet_gateway_id | ID of the Internet Gateway |
| public_subnet_ids | IDs of the public subnets |
| private_web_subnet_ids | IDs of the private web tier subnets |
| private_app_subnet_ids | IDs of the private app tier subnets |
| private_data_subnet_ids | IDs of the private data tier subnets |
| nat_gateway_ids | IDs of the NAT Gateways |
| nat_gateway_ips | Elastic IP addresses of the NAT Gateways |
| public_route_table_id | ID of the public route table |
| private_route_table_ids | IDs of the private route tables |
| availability_zones | List of availability zones used |

## Validation

The module includes input validation for:

- **VPC CIDR**: Must be a valid IPv4 CIDR block
- **Subnet Count**: At least 2 subnets required for each tier for high availability

## Testing

Unit tests are provided using Terratest. To run the tests:

```bash
cd test
go mod tidy
go test -v -timeout 30m
```

## High Availability

- **Multi-AZ**: Resources are distributed across multiple availability zones
- **NAT Gateway Redundancy**: One NAT Gateway per availability zone
- **Route Table Redundancy**: Separate route tables for each AZ

## Security

- **Private Subnets**: Application and database tiers are in private subnets
- **Network Segmentation**: Clear separation between web, app, and data tiers
- **Controlled Internet Access**: Only public subnets have direct internet access

## Cost Optimization

- **Right-sized NAT Gateways**: Uses standard NAT Gateways (can be optimized per environment)
- **Efficient Routing**: Optimized route table associations
- **Resource Tagging**: Comprehensive tagging for cost tracking

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources

- aws_vpc
- aws_internet_gateway
- aws_subnet (public and private)
- aws_eip
- aws_nat_gateway
- aws_route_table
- aws_route_table_association
- data.aws_availability_zones