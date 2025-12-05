#!/bin/bash

# AWS Gateway API Controller Destroy Script
# This script removes all AWS Gateway API Controller resources

set -e

# Configuration Variables - REPLACE THESE VALUES
CLUSTER_NAME="poc-project-cluster"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="141745357479"
POLICY_NAME="VPCLatticeControllerIAMPolicy"
SERVICE_ACCOUNT_NAME="gateway-api-controller"
NAMESPACE="aws-application-networking-system"

echo "=== AWS Gateway API Controller Destruction ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
echo ""

# Step 1: Remove Example Resources
echo "Step 1: Removing example resources..."
kubectl delete -f product-inventory-route.yaml --ignore-not-found=true
kubectl delete -f ecommerce-api-gateway.yaml --ignore-not-found=true
kubectl delete -f product-inventory-service.yaml --ignore-not-found=true
echo "Example resources removed!"

# Step 2: Remove GatewayClass
echo "Step 2: Removing GatewayClass..."
kubectl delete -f gatewayclass.yaml --ignore-not-found=true
echo "GatewayClass removed!"

# Step 3: Uninstall Controller
echo "Step 3: Uninstalling AWS Gateway API Controller..."

# Check if Helm release exists
if helm list -n $NAMESPACE | grep -q gateway-api-controller; then
    echo "Removing Helm installation..."
    helm uninstall gateway-api-controller -n $NAMESPACE
else
    echo "No Helm installation found, checking for kubectl deployment..."
    kubectl delete deployment -n $NAMESPACE --all --ignore-not-found=true
    kubectl delete service -n $NAMESPACE --all --ignore-not-found=true
    kubectl delete configmap -n $NAMESPACE --all --ignore-not-found=true
    kubectl delete secret -n $NAMESPACE --all --ignore-not-found=true
fi

# Delete namespace
echo "Deleting namespace..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

# Force delete if stuck in terminating state
sleep 10
if kubectl get namespace $NAMESPACE 2>/dev/null | grep -q Terminating; then
    echo "Namespace stuck in Terminating state, force deleting..."
    kubectl get namespace $NAMESPACE -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - || echo "Force delete attempted"
fi

echo "Controller uninstalled!"

# Step 4: Remove Gateway API CRDs
echo "Step 4: Removing Gateway API CRDs..."
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml --ignore-not-found=true
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --ignore-not-found=true
echo "Gateway API CRDs removed!"

# Step 5: Clean Up AWS Resources
echo "Step 5: Cleaning up AWS resources..."

# Remove IRSA
echo "Removing IRSA..."
eksctl delete iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --region=$AWS_REGION \
    --namespace=$NAMESPACE \
    --name=$SERVICE_ACCOUNT_NAME || echo "IRSA may not exist or already deleted"

# Remove IAM Policy
echo "Removing IAM policy..."
POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME"
aws iam delete-policy \
    --policy-arn $POLICY_ARN \
    --region $AWS_REGION || echo "Policy may not exist or already deleted"

# Remove Security Group Rules (Optional)
echo "Removing security group rules..."
CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text 2>/dev/null || echo "")

if [ ! -z "$CLUSTER_SG" ]; then
    # Get VPC Lattice prefix lists
    VPC_LATTICE_IPV4_PREFIX_LIST=$(aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?PrefixListName=='com.amazonaws.vpce.$AWS_REGION.vpce-svc'].PrefixListId" --output text 2>/dev/null || echo "")
    VPC_LATTICE_IPV6_PREFIX_LIST=$(aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?PrefixListName=='com.amazonaws.vpce.$AWS_REGION.ipv6.vpce-svc'].PrefixListId" --output text 2>/dev/null || echo "")

    # Remove IPv4 rule
    if [ ! -z "$VPC_LATTICE_IPV4_PREFIX_LIST" ]; then
        aws ec2 revoke-security-group-ingress \
            --region $AWS_REGION \
            --group-id $CLUSTER_SG \
            --protocol tcp \
            --port 443 \
            --source-prefix-list-id $VPC_LATTICE_IPV4_PREFIX_LIST || echo "IPv4 rule may not exist"
    fi

    # Remove IPv6 rule
    if [ ! -z "$VPC_LATTICE_IPV6_PREFIX_LIST" ]; then
        aws ec2 revoke-security-group-ingress \
            --region $AWS_REGION \
            --group-id $CLUSTER_SG \
            --protocol tcp \
            --port 443 \
            --source-prefix-list-id $VPC_LATTICE_IPV6_PREFIX_LIST || echo "IPv6 rule may not exist"
    fi
fi

echo "Security group rules removed!"

# Step 6: Verify Cleanup
echo "Step 6: Verifying cleanup..."
echo "Checking for remaining resources..."

# Check pods
REMAINING_PODS=$(kubectl get pods -n $NAMESPACE 2>/dev/null | wc -l || echo "0")
if [ "$REMAINING_PODS" -gt 1 ]; then
    echo "Warning: Some pods may still be terminating in namespace $NAMESPACE"
else
    echo "✅ No pods found in namespace $NAMESPACE"
fi

# Check CRDs
GATEWAY_CRDS=$(kubectl get crd | grep gateway.networking.k8s.io | wc -l || echo "0")
if [ "$GATEWAY_CRDS" -gt 0 ]; then
    echo "Warning: Some Gateway API CRDs may still exist"
else
    echo "✅ Gateway API CRDs removed"
fi

# Check IAM policy
POLICY_EXISTS=$(aws iam get-policy --policy-arn $POLICY_ARN 2>/dev/null && echo "exists" || echo "not-found")
if [ "$POLICY_EXISTS" = "exists" ]; then
    echo "Warning: IAM policy still exists"
else
    echo "✅ IAM policy removed"
fi

echo ""
echo "=== Destruction Complete! ==="
echo "AWS Gateway API Controller has been removed from cluster: $CLUSTER_NAME"
echo ""
echo "Note: VPC Lattice resources in AWS may take a few minutes to fully terminate."
echo "Check AWS Console for any remaining VPC Lattice Service Networks or Target Groups."
