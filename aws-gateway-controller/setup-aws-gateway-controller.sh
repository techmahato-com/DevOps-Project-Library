#!/bin/bash

# AWS Gateway API Controller Complete Setup Script
# Based on: https://www.gateway-api-controller.eks.aws.dev/dev/guides/deploy/

set -e

# Configuration Variables - REPLACE THESE VALUES
CLUSTER_NAME="poc-project-cluster"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="141745357479"
POLICY_NAME="VPCLatticeControllerIAMPolicy"
SERVICE_ACCOUNT_NAME="gateway-api-controller"
NAMESPACE="aws-application-networking-system"

echo "=== AWS Gateway API Controller Setup ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"

# Step 1: Install Prerequisites
echo "Step 1: Installing prerequisites..."

# Install AWS CLI (if not present)
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Install kubectl (if not present)
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Install helm (if not present)
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Install eksctl (if not present)
if ! command -v eksctl &> /dev/null; then
    echo "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

# Install jq (if not present)
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get update && sudo apt-get install -y jq
fi

echo "Prerequisites installed successfully!"

# Step 2: Install Gateway API CRDs
echo "Step 2: Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Step 3: Configure Security Group for VPC Lattice
echo "Step 3: Configuring security group for VPC Lattice..."

# Get cluster security group
CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
echo "Cluster Security Group: $CLUSTER_SG"

# Get VPC Lattice managed prefix lists
VPC_LATTICE_IPV4_PREFIX_LIST=$(aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?PrefixListName=='com.amazonaws.vpce.$AWS_REGION.vpce-svc'].PrefixListId" --output text)
VPC_LATTICE_IPV6_PREFIX_LIST=$(aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?PrefixListName=='com.amazonaws.vpce.$AWS_REGION.ipv6.vpce-svc'].PrefixListId" --output text)

echo "VPC Lattice IPv4 Prefix List: $VPC_LATTICE_IPV4_PREFIX_LIST"
echo "VPC Lattice IPv6 Prefix List: $VPC_LATTICE_IPV6_PREFIX_LIST"

# Authorize ingress from VPC Lattice IPv4
if [ ! -z "$VPC_LATTICE_IPV4_PREFIX_LIST" ]; then
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $CLUSTER_SG \
        --protocol tcp \
        --port 443 \
        --source-prefix-list-id $VPC_LATTICE_IPV4_PREFIX_LIST || echo "IPv4 rule may already exist"
fi

# Authorize ingress from VPC Lattice IPv6 (if available)
if [ ! -z "$VPC_LATTICE_IPV6_PREFIX_LIST" ]; then
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $CLUSTER_SG \
        --protocol tcp \
        --port 443 \
        --source-prefix-list-id $VPC_LATTICE_IPV6_PREFIX_LIST || echo "IPv6 rule may already exist"
fi

# Step 4: Download and create IAM policy
echo "Step 4: Creating IAM policy..."
curl -o recommended-inline-policy.json https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/recommended-inline-policy.json

aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://recommended-inline-policy.json \
    --region $AWS_REGION || echo "Policy may already exist"

POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME"
echo "Policy ARN: $POLICY_ARN"

# Step 5: Create namespace
echo "Step 5: Creating namespace..."
kubectl create namespace $NAMESPACE || echo "Namespace may already exist"

# Step 6: Create IRSA (IAM Role for Service Account)
echo "Step 6: Creating IRSA..."

# Check if OIDC provider exists, create if not
OIDC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
OIDC_PROVIDER_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, '$OIDC_ID')]" --output text)

if [ -z "$OIDC_PROVIDER_EXISTS" ]; then
    echo "Creating OIDC provider..."
    eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --region $AWS_REGION --approve
fi

# Create service account with IRSA
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --region=$AWS_REGION \
    --namespace=$NAMESPACE \
    --name=$SERVICE_ACCOUNT_NAME \
    --attach-policy-arn=$POLICY_ARN \
    --override-existing-serviceaccounts \
    --approve

# Step 7: Install AWS Gateway API Controller
echo "Step 7: Installing AWS Gateway API Controller..."

# Option A: Helm Installation (ACTIVE)
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install gateway-api-controller eks/aws-gateway-controller-chart \
    --version=v1.0.6 \
    --namespace=$NAMESPACE \
    --set=serviceAccount.create=false \
    --set=serviceAccount.name=$SERVICE_ACCOUNT_NAME

# Option B: kubectl Installation (COMMENTED OUT)
# kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/v1.0.6/deploy/deploy.yaml

# Step 8: Create GatewayClass
echo "Step 8: Creating GatewayClass..."
kubectl apply -f gatewayclass.yaml

echo "=== Setup Complete! ==="
echo "Next steps:"
echo "1. Apply your Gateway and HTTPRoute manifests"
echo "2. Verify controller is running: kubectl get pods -n $NAMESPACE"
echo "3. Check GatewayClass: kubectl get gatewayclass"
