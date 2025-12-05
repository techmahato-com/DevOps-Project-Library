#!/bin/bash

# Get VPC Lattice service details
VPC_LATTICE_DOMAIN=$(aws vpc-lattice list-services --region us-east-1 --query "items[0].dnsEntry.domainName" --output text)
VPC_ID=$(aws eks describe-cluster --name poc-project-cluster --region us-east-1 --query "cluster.resourcesVpcConfig.vpcId" --output text)

# Create VPC Link for API Gateway
VPC_LINK_ID=$(aws apigatewayv2 create-vpc-link \
  --name "ecommerce-vpc-link" \
  --subnet-ids $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0:2].SubnetId" --output text | tr '\t' ' ') \
  --region us-east-1 \
  --query "VpcLinkId" --output text)

echo "VPC Link ID: $VPC_LINK_ID"
echo "VPC Lattice Domain: $VPC_LATTICE_DOMAIN"
echo "Use these values to create API Gateway integration"
