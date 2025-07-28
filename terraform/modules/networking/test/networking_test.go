package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestNetworkingModule(t *testing.T) {
	t.Parallel()

	// Define the Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code that will be tested
		TerraformDir: "../",

		// Variables to pass to the Terraform code using -var options
		Vars: map[string]interface{}{
			"environment":                 "test",
			"vpc_cidr":                   "10.0.0.0/16",
			"public_subnet_cidrs":        []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_web_subnet_cidrs":   []string{"10.0.10.0/24", "10.0.11.0/24"},
			"private_app_subnet_cidrs":   []string{"10.0.20.0/24", "10.0.21.0/24"},
			"private_data_subnet_cidrs":  []string{"10.0.30.0/24", "10.0.31.0/24"},
			"common_tags": map[string]string{
				"Environment": "test",
				"Project":     "automated-cloud-infrastructure",
			},
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply"
	terraform.InitAndApply(t, terraformOptions)

	// Test VPC creation
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId, "VPC ID should not be empty")

	vpcCidr := terraform.Output(t, terraformOptions, "vpc_cidr_block")
	assert.Equal(t, "10.0.0.0/16", vpcCidr, "VPC CIDR should match expected value")

	// Test Internet Gateway creation
	igwId := terraform.Output(t, terraformOptions, "internet_gateway_id")
	assert.NotEmpty(t, igwId, "Internet Gateway ID should not be empty")

	// Test public subnets
	publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.Len(t, publicSubnetIds, 2, "Should have 2 public subnets")

	// Test private web subnets
	privateWebSubnetIds := terraform.OutputList(t, terraformOptions, "private_web_subnet_ids")
	assert.Len(t, privateWebSubnetIds, 2, "Should have 2 private web subnets")

	// Test private app subnets
	privateAppSubnetIds := terraform.OutputList(t, terraformOptions, "private_app_subnet_ids")
	assert.Len(t, privateAppSubnetIds, 2, "Should have 2 private app subnets")

	// Test private data subnets
	privateDataSubnetIds := terraform.OutputList(t, terraformOptions, "private_data_subnet_ids")
	assert.Len(t, privateDataSubnetIds, 2, "Should have 2 private data subnets")

	// Test NAT Gateways
	natGatewayIds := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Len(t, natGatewayIds, 2, "Should have 2 NAT Gateways")

	natGatewayIps := terraform.OutputList(t, terraformOptions, "nat_gateway_ips")
	assert.Len(t, natGatewayIps, 2, "Should have 2 NAT Gateway IPs")

	// Test route tables
	publicRouteTableId := terraform.Output(t, terraformOptions, "public_route_table_id")
	assert.NotEmpty(t, publicRouteTableId, "Public route table ID should not be empty")

	privateRouteTableIds := terraform.OutputList(t, terraformOptions, "private_route_table_ids")
	assert.Len(t, privateRouteTableIds, 2, "Should have 2 private route tables")

	// Test availability zones
	availabilityZones := terraform.OutputList(t, terraformOptions, "availability_zones")
	assert.GreaterOrEqual(t, len(availabilityZones), 2, "Should have at least 2 availability zones")
}

func TestNetworkingModuleValidation(t *testing.T) {
	t.Parallel()

	// Test invalid VPC CIDR
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"environment": "test",
			"vpc_cidr":    "invalid-cidr",
		},
	})

	// This should fail during plan phase due to validation
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Should fail with invalid VPC CIDR")

	// Test insufficient public subnets
	terraformOptions2 := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"environment":          "test",
			"public_subnet_cidrs": []string{"10.0.1.0/24"}, // Only 1 subnet
		},
	})

	_, err2 := terraform.InitAndPlanE(t, terraformOptions2)
	assert.Error(t, err2, "Should fail with insufficient public subnets")
}