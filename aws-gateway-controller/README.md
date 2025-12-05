# AWS Gateway API Controller - Manual Deployment Guide

This guide provides detailed manual steps to deploy and destroy AWS Gateway API Controller infrastructure on EKS. Each step is explained clearly so you understand what you're doing and why.

## 📋 Prerequisites

### Required Tools and Access
Before starting, ensure you have:

- **AWS Account** with appropriate permissions
- **Existing EKS Cluster** (running and accessible)
- **AWS CLI** v2.x installed and configured
- **kubectl** v1.28+ installed and configured
- **helm** v3.x installed
- **eksctl** installed
- **jq** installed
- **Terminal/Command Line** access (Linux/macOS/WSL)

### IAM Permissions Required
Your AWS user/role needs these permissions:
- **EKS**: `eks:DescribeCluster`, `eks:ListClusters`
- **IAM**: `iam:CreatePolicy`, `iam:DeletePolicy`, `iam:AttachRolePolicy`, `iam:DetachRolePolicy`, `iam:CreateRole`, `iam:DeleteRole`
- **EC2**: `ec2:DescribeSecurityGroups`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:DescribeManagedPrefixLists`
- **VPC Lattice**: `vpc-lattice:*`
- **CloudFormation**: `cloudformation:*`

### Verify Prerequisites
```bash
# Check AWS CLI and credentials
aws --version
aws sts get-caller-identity

# Check kubectl access to your cluster
kubectl version --client
kubectl cluster-info
kubectl get nodes

# Check other required tools
helm version
eksctl version
jq --version
```

## 🚀 Manual Deployment Steps

### Step 1: Prepare Your Environment

#### 1.1 Set Environment Variables
Replace these values with your actual cluster information:

```bash
# Set your cluster details
export CLUSTER_NAME="your-cluster-name"
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export POLICY_NAME="VPCLatticeControllerIAMPolicy"
export SERVICE_ACCOUNT_NAME="gateway-api-controller"
export NAMESPACE="aws-application-networking-system"

# Verify your settings
echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
```

#### 1.2 Get Your Cluster Information
```bash
# List available EKS clusters
aws eks list-clusters --region $AWS_REGION

# Get your AWS account ID
aws sts get-caller-identity --query Account --output text

# Update kubeconfig for your cluster
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster access
kubectl get nodes
```

### Step 2: Install Gateway API CRDs

#### 2.1 Install Experimental Gateway API CRDs (Required First)
```bash
# Install experimental CRDs first (v1.2.0) - required for controller compatibility
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml

# Verify experimental CRDs are installed with correct versions
kubectl get crd grpcroutes.gateway.networking.k8s.io -o jsonpath='{.spec.versions[*].name}'
# Expected output: v1
```

#### 2.2 Install Standard Gateway API CRDs
```bash
# Install standard Gateway API CRDs (v1.0.0)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Verify all CRDs are installed
kubectl get crd | grep gateway.networking.k8s.io
```

**Expected Output:**
```
backendlbpolicies.gateway.networking.k8s.io
backendtlspolicies.gateway.networking.k8s.io
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
grpcroutes.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
referencegrants.gateway.networking.k8s.io
tcproutes.gateway.networking.k8s.io
tlsroutes.gateway.networking.k8s.io
udproutes.gateway.networking.k8s.io
```

**Important:** Install experimental CRDs FIRST to ensure GRPCRoute has v1 version, not v1alpha2.

### Step 3: Configure Security Groups for VPC Lattice

#### 3.1 Get Cluster Security Group
```bash
# Get your EKS cluster's security group ID
CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)

echo "Cluster Security Group: $CLUSTER_SG"
```

#### 3.2 Get VPC Lattice Managed Prefix Lists
```bash
# Get VPC Lattice IPv4 prefix list (region-specific naming)
VPC_LATTICE_IPV4_PREFIX_LIST=$(aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?PrefixListName=='com.amazonaws.$AWS_REGION.vpc-lattice'].PrefixListId" --output text)

# Get VPC Lattice IPv6 prefix list (if available)
VPC_LATTICE_IPV6_PREFIX_LIST=$(aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?PrefixListName=='com.amazonaws.$AWS_REGION.ipv6.vpc-lattice'].PrefixListId" --output text)

echo "VPC Lattice IPv4 Prefix List: $VPC_LATTICE_IPV4_PREFIX_LIST"
echo "VPC Lattice IPv6 Prefix List: $VPC_LATTICE_IPV6_PREFIX_LIST"

# If above doesn't work, list all VPC Lattice related prefix lists
if [ -z "$VPC_LATTICE_IPV4_PREFIX_LIST" ]; then
    echo "Checking available VPC Lattice prefix lists..."
    aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?contains(PrefixListName, 'vpc-lattice')].{Name:PrefixListName,Id:PrefixListId}" --output table
fi
```

#### 3.3 Authorize Ingress from VPC Lattice
```bash
# Authorize ingress from VPC Lattice IPv4 (port 443 for HTTPS)
if [ ! -z "$VPC_LATTICE_IPV4_PREFIX_LIST" ]; then
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $CLUSTER_SG \
        --protocol tcp \
        --port 443 \
        --source-prefix-list-id $VPC_LATTICE_IPV4_PREFIX_LIST
    echo "✅ IPv4 ingress rule added"
else
    echo "❌ IPv4 prefix list not found"
fi

# Authorize ingress from VPC Lattice IPv6 (if available)
if [ ! -z "$VPC_LATTICE_IPV6_PREFIX_LIST" ]; then
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $CLUSTER_SG \
        --protocol tcp \
        --port 443 \
        --source-prefix-list-id $VPC_LATTICE_IPV6_PREFIX_LIST
    echo "✅ IPv6 ingress rule added"
else
    echo "ℹ️ IPv6 prefix list not available in this region"
fi
```

### Step 4: Create IAM Policy for VPC Lattice Controller

#### 4.1 Download the Recommended IAM Policy
```bash
# Download AWS recommended IAM policy for the controller
curl -o recommended-inline-policy.json https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/recommended-inline-policy.json

# Review the policy (optional)
cat recommended-inline-policy.json | jq '.'
```

#### 4.2 Create IAM Policy
```bash
# Create the IAM policy
aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://recommended-inline-policy.json \
    --region $AWS_REGION

# Get the policy ARN
POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME"
echo "Policy ARN: $POLICY_ARN"

# Verify policy creation
aws iam get-policy --policy-arn $POLICY_ARN
```

### Step 5: Create Namespace for Controller

#### 5.1 Create the Namespace
```bash
# Create the namespace for AWS Gateway API Controller
kubectl create namespace $NAMESPACE

# Verify namespace creation
kubectl get namespace $NAMESPACE
```

### Step 6: Set Up IRSA (IAM Role for Service Account)

#### What is IRSA?
**IRSA (IAM Role for Service Account)** is an AWS feature that allows Kubernetes service accounts to securely assume AWS IAM roles without storing AWS credentials in pods.

**How IRSA Works:**
1. **OIDC Provider**: EKS cluster has an OpenID Connect (OIDC) identity provider
2. **Trust Relationship**: IAM role trusts the EKS OIDC provider
3. **Service Account Annotation**: Kubernetes service account is annotated with IAM role ARN
4. **Token Exchange**: Pod gets a JWT token that can be exchanged for AWS credentials
5. **Automatic Authentication**: AWS SDK automatically uses the token for API calls

**Benefits of IRSA:**
- ✅ **No hardcoded credentials** in containers or config files
- ✅ **Automatic credential rotation** handled by AWS
- ✅ **Fine-grained permissions** per service account
- ✅ **Secure token exchange** using OIDC standard
- ✅ **Audit trail** through CloudTrail for all API calls

**IRSA vs Traditional Methods:**
```
❌ Traditional: Store AWS keys in secrets → Security risk
✅ IRSA: Use temporary tokens → Secure & automatic
```

#### 6.1 Check OIDC Provider
```bash
# Check if OIDC provider exists for your cluster
OIDC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo "OIDC ID: $OIDC_ID"

# Check if OIDC provider is associated
OIDC_PROVIDER_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, '$OIDC_ID')]" --output text)

if [ -z "$OIDC_PROVIDER_EXISTS" ]; then
    echo "Creating OIDC provider..."
    eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --region $AWS_REGION --approve
else
    echo "✅ OIDC provider already exists"
fi
```

#### 6.2 Create Service Account with IRSA
```bash
# Create service account with IAM role
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --region=$AWS_REGION \
    --namespace=$NAMESPACE \
    --name=$SERVICE_ACCOUNT_NAME \
    --attach-policy-arn=$POLICY_ARN \
    --override-existing-serviceaccounts \
    --approve

# Verify IRSA creation
eksctl get iamserviceaccount --cluster=$CLUSTER_NAME --region=$AWS_REGION --namespace=$NAMESPACE --name=$SERVICE_ACCOUNT_NAME
```

**What happens during IRSA creation:**
1. **CloudFormation Stack**: Creates IAM role with trust policy for EKS OIDC
2. **Policy Attachment**: Attaches VPC Lattice permissions to the role
3. **Service Account**: Creates Kubernetes service account with role annotation
4. **Trust Policy**: Configures role to trust specific service account in specific namespace

**Expected Output:**
```
NAMESPACE                               NAME                    ROLE ARN
aws-application-networking-system       gateway-api-controller  arn:aws:iam::123456789012:role/eksctl-cluster-addon-iamserviceac-Role1-XXXXX
```

### Step 7: Install AWS Gateway API Controller

#### 7.1 Install Controller via kubectl (Recommended)
```bash
# Install AWS Gateway API Controller using kubectl with kustomize
kubectl apply -k "github.com/aws/aws-application-networking-k8s/config/default?ref=v1.1.7"

# Verify installation
kubectl get deployment -n $NAMESPACE
```

#### 7.2 Configure Controller Environment Variables (Critical Step)
```bash
# The controller needs AWS_REGION and CLUSTER_NAME environment variables to work properly
kubectl patch deployment gateway-api-controller -n $NAMESPACE --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/1/env/-", "value": {"name": "AWS_REGION", "value": "'$AWS_REGION'"}},
  {"op": "add", "path": "/spec/template/spec/containers/1/env/-", "value": {"name": "CLUSTER_NAME", "value": "'$CLUSTER_NAME'"}}
]'

# Wait for pods to restart with new environment variables
kubectl rollout status deployment/gateway-api-controller -n $NAMESPACE
```

**Note:** You may see warnings about duplicate environment variables - this is normal and can be ignored.

#### 7.3 Alternative: Helm Installation (Not Recommended - Chart Not Available)
```bash
# Note: AWS Gateway Controller Helm chart is not available in EKS repository
# The following commands will fail:
helm repo add eks https://aws.github.io/eks-charts
helm search repo eks | grep -i gateway
# Result: No gateway controller chart found

# Use kubectl method above instead
```

#### 7.4 Verify Controller Installation
```bash
# Check controller pods (should show 2 running pods)
kubectl get pods -n $NAMESPACE

# Expected output:
# NAME                                      READY   STATUS    RESTARTS   AGE
# gateway-api-controller-xxxxx-xxxxx        2/2     Running   0          2m
# gateway-api-controller-xxxxx-xxxxx        2/2     Running   0          2m

# Check controller logs for successful startup
kubectl logs -n $NAMESPACE deployment/gateway-api-controller --tail=20

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l control-plane=gateway-api-controller -n $NAMESPACE --timeout=300s
```

### Step 8: Create GatewayClass

#### What is GatewayClass?
**GatewayClass** is a Kubernetes resource that defines a template for creating Gateway instances. It acts as a bridge between the Gateway API and the underlying infrastructure provider (in this case, AWS VPC Lattice).

**Key Concepts:**
- **Controller Name**: Specifies which controller manages this GatewayClass
- **Template**: Defines configuration that will be applied to all Gateways using this class
- **Infrastructure Binding**: Links Gateway API resources to AWS VPC Lattice services

**Think of it like:**
- **GatewayClass** = Blueprint/Template (defines HOW gateways work)
- **Gateway** = Instance (defines WHERE traffic goes)
- **HTTPRoute** = Rules (defines WHICH traffic gets routed)

#### 8.1 Create GatewayClass Resource
```bash
# Create gatewayclass.yaml file
cat > gatewayclass.yaml << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: amazon-vpc-lattice
spec:
  controllerName: application-networking.k8s.aws/gateway-api-controller
EOF

# Apply the GatewayClass
kubectl apply -f gatewayclass.yaml

# Verify GatewayClass creation
kubectl get gatewayclass
```

**Expected Output:**
```
NAME                 CONTROLLER                                              ACCEPTED   AGE
amazon-vpc-lattice   application-networking.k8s.aws/gateway-api-controller   True       30s
```

**What happens when you create this GatewayClass:**
1. **Controller Recognition**: The AWS Gateway Controller recognizes it owns this GatewayClass
2. **VPC Lattice Binding**: Links Gateway API to AWS VPC Lattice infrastructure
3. **Gateway Template**: Any Gateway using `gatewayClassName: amazon-vpc-lattice` will use VPC Lattice
4. **Status Update**: Controller sets `Accepted: True` when ready to manage Gateways

## ✅ Verification Steps

### Step 1: Check All Components
```bash
# Check controller pods
kubectl get pods -n $NAMESPACE
# Expected: 2 pods in Running status

# Check GatewayClass
kubectl get gatewayclass
# Expected: amazon-vpc-lattice with Accepted=True

# Check service account
kubectl get serviceaccount -n $NAMESPACE
# Expected: gateway-api-controller with annotations for IAM role

# Check IAM policy
aws iam get-policy --policy-arn $POLICY_ARN
# Expected: Policy details returned

# Check IRSA
eksctl get iamserviceaccount --cluster=$CLUSTER_NAME --region=$AWS_REGION
# Expected: Service account with IAM role ARN
```

### Step 2: Deploy Sample E-commerce Application

#### 2.1 Create Product Inventory Service and Deployment
```bash
# Create product-inventory-service.yaml
cat > product-inventory-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: product-inventory-service
  namespace: default
spec:
  selector:
    app: product-inventory
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-inventory-deployment
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-inventory
  template:
    metadata:
      labels:
        app: product-inventory
    spec:
      containers:
      - name: product-inventory
        image: nginx:latest
        ports:
        - containerPort: 8080
EOF

# Apply the service and deployment
kubectl apply -f product-inventory-service.yaml

# Verify deployment
kubectl get service product-inventory-service
kubectl get deployment product-inventory-deployment
kubectl get pods -l app=product-inventory
```

#### 2.2 Create E-commerce API Gateway
```bash
# Create ecommerce-api-gateway.yaml
cat > ecommerce-api-gateway.yaml << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: ecommerce-api-gateway
  namespace: default
spec:
  gatewayClassName: amazon-vpc-lattice
  listeners:
  - name: http-api
    protocol: HTTP
    port: 80
EOF

# Apply the Gateway
kubectl apply -f ecommerce-api-gateway.yaml

# Check Gateway status
kubectl get gateway
kubectl describe gateway ecommerce-api-gateway
```

#### 2.3 Create Product Inventory Route
```bash
# Create product-inventory-route.yaml
cat > product-inventory-route.yaml << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: product-inventory-route
  namespace: default
spec:
  parentRefs:
  - name: ecommerce-api-gateway
  hostnames:
  - "api-ecommerce-shop.task20domainname.xyz"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api/products
    backendRefs:
    - name: product-inventory-service
      port: 80
EOF

# Apply the HTTPRoute
kubectl apply -f product-inventory-route.yaml

# Check HTTPRoute status
kubectl get httproute
kubectl describe httproute product-inventory-route
```

### Step 3: Monitor VPC Lattice Resources
```bash
# Check VPC Lattice Service Networks (may take 5-10 minutes to appear)
aws vpc-lattice list-service-networks --region $AWS_REGION

# Check VPC Lattice Target Groups
aws vpc-lattice list-target-groups --region $AWS_REGION

# Monitor controller logs for VPC Lattice resource creation
kubectl logs -n $NAMESPACE deployment/gateway-api-controller -f
```

## 🗑️ Manual Cleanup/Destruction

### Step 1: Remove E-commerce Application Resources
```bash
# Remove Product Inventory Route
kubectl delete -f product-inventory-route.yaml

# Remove E-commerce API Gateway
kubectl delete -f ecommerce-api-gateway.yaml

# Remove Product Inventory Service and Deployment
kubectl delete -f product-inventory-service.yaml

# Verify removal
kubectl get gateway,httproute,service product-inventory-service
```

### Step 2: Remove GatewayClass
```bash
# Remove GatewayClass
kubectl delete -f gatewayclass.yaml

# Verify removal
kubectl get gatewayclass
```

### Step 3: Uninstall Controller
```bash
# Check Helm release
helm list -n $NAMESPACE

# Uninstall Helm release
helm uninstall gateway-api-controller -n $NAMESPACE

# Delete namespace
kubectl delete namespace $NAMESPACE

# Verify removal
kubectl get namespace $NAMESPACE
```

### Step 4: Remove Gateway API CRDs
```bash
# Remove experimental CRDs
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml

# Remove standard CRDs
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Verify CRD removal
kubectl get crd | grep gateway.networking.k8s.io
```

### Step 5: Clean Up AWS Resources

#### 5.1 Remove IRSA
```bash
# Delete IRSA service account
eksctl delete iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --region=$AWS_REGION \
    --namespace=$NAMESPACE \
    --name=$SERVICE_ACCOUNT_NAME

# Verify IRSA removal
eksctl get iamserviceaccount --cluster=$CLUSTER_NAME --region=$AWS_REGION
```

#### 5.2 Remove IAM Policy
```bash
# List entities attached to policy
aws iam list-entities-for-policy --policy-arn $POLICY_ARN

# Delete IAM policy
aws iam delete-policy --policy-arn $POLICY_ARN

# Verify policy removal
aws iam get-policy --policy-arn $POLICY_ARN
```

#### 5.3 Remove Security Group Rules (Optional)
```bash
# Remove IPv4 ingress rule
if [ ! -z "$VPC_LATTICE_IPV4_PREFIX_LIST" ]; then
    aws ec2 revoke-security-group-ingress \
        --region $AWS_REGION \
        --group-id $CLUSTER_SG \
        --protocol tcp \
        --port 443 \
        --source-prefix-list-id $VPC_LATTICE_IPV4_PREFIX_LIST
fi

# Remove IPv6 ingress rule (if exists)
if [ ! -z "$VPC_LATTICE_IPV6_PREFIX_LIST" ]; then
    aws ec2 revoke-security-group-ingress \
        --region $AWS_REGION \
        --group-id $CLUSTER_SG \
        --protocol tcp \
        --port 443 \
        --source-prefix-list-id $VPC_LATTICE_IPV6_PREFIX_LIST
fi
```

### Step 6: Clean Up VPC Lattice Resources
```bash
# List and delete any remaining VPC Lattice resources
aws vpc-lattice list-service-networks --region $AWS_REGION
aws vpc-lattice list-target-groups --region $AWS_REGION

# Delete target groups if any remain
TARGET_GROUPS=$(aws vpc-lattice list-target-groups --region $AWS_REGION --query "items[?contains(name, 'product-inventory')].id" --output text)
for tg in $TARGET_GROUPS; do
    aws vpc-lattice delete-target-group --target-group-identifier $tg --region $AWS_REGION
done
```

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. Controller Pods CrashLoopBackOff
**Check logs:**
```bash
kubectl logs -n $NAMESPACE deployment/gateway-api-controller --tail=50
```

**Common fixes:**
- **Missing TLSRoute CRD**: Install experimental CRDs
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml
  ```
- **Missing AWS_REGION environment variable**: 
  ```bash
  kubectl patch deployment gateway-api-controller -n $NAMESPACE --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/1/env/-", "value": {"name": "AWS_REGION", "value": "'$AWS_REGION'"}}]'
  ```
- **Missing CLUSTER_NAME environment variable**:
  ```bash
  kubectl patch deployment gateway-api-controller -n $NAMESPACE --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/1/env/-", "value": {"name": "CLUSTER_NAME", "value": "'$CLUSTER_NAME'"}}]'
  ```
- **Wrong GRPCRoute CRD version**: Delete and reinstall CRDs in correct order
  ```bash
  kubectl delete crd grpcroutes.gateway.networking.k8s.io
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml
  kubectl delete pods -n $NAMESPACE --all
  ```

#### 2. VPC Lattice Prefix Lists Not Found
**Issue**: Commands return empty prefix list IDs
**Cause**: Region-specific naming convention
**Fix**: Use correct prefix list names:
```bash
# Correct format for us-east-1:
VPC_LATTICE_IPV4_PREFIX_LIST=$(aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?PrefixListName=='com.amazonaws.$AWS_REGION.vpc-lattice'].PrefixListId" --output text)

# List all available prefix lists if needed:
aws ec2 describe-managed-prefix-lists --region $AWS_REGION --query "PrefixLists[?contains(PrefixListName, 'vpc-lattice')].{Name:PrefixListName,Id:PrefixListId}" --output table
```

#### 3. Gateway Not Programmed
**Check Gateway status:**
```bash
kubectl describe gateway ecommerce-api-gateway
```

**Common causes:**
- VPC Lattice Service Network creation in progress (5-10 minutes)
- AWS permissions insufficient
- Region doesn't support VPC Lattice

#### 4. IRSA Creation Failed
**Check OIDC provider:**
```bash
aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer"
```

**Fix:**
```bash
eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --region $AWS_REGION --approve
```

#### 5. Helm Chart Not Found
**Issue**: `aws-gateway-controller-chart` not found in EKS repository
**Solution**: Use kubectl installation method instead of Helm
```bash
kubectl apply -k "github.com/aws/aws-application-networking-k8s/config/default?ref=v1.1.7"
```

#### 6. HTTPRoute FailedDeployModel - No Credentials
**Symptoms:**
```bash
kubectl describe httproute <route-name>
# Shows: FailedDeployModel: NoCredentialProviders: no valid providers in chain
```

**Cause:** Controller pods need to restart after IRSA setup to initialize AWS credential chain

**Fix:**
```bash
# Restart controller pods to refresh AWS credentials
kubectl delete pods -n $NAMESPACE --all

# Wait for pods to restart
kubectl get pods -n $NAMESPACE -w

# Verify HTTPRoute status after restart
kubectl describe httproute <route-name>
```

**Root Cause:** Controller pods sometimes don't immediately pick up IRSA credentials and need a restart to properly initialize the AWS SDK credential chain.

**Alternative Cause:** If the issue persists after pod restart, check for conflicting EKS Pod Identity associations:
```bash
# Check for Pod Identity associations
aws eks list-pod-identity-associations --cluster-name $CLUSTER_NAME --region $AWS_REGION

# If found, delete the conflicting association
aws eks delete-pod-identity-association --cluster-name $CLUSTER_NAME --association-id <association-id> --region $AWS_REGION

# Restart pods again
kubectl delete pods -n $NAMESPACE --all
```

#### 7. VPC Lattice Resource Creation Errors
**Symptoms:**
```bash
kubectl describe httproute <route-name>
# Shows: ConflictException: Invalid resource status for this operation, resource id tg-xxx, status: CREATE_IN_PROGRESS
# Or: failed ServiceManager.Upsert due to not found, Service network <gateway-name>
```

**Cause:** VPC Lattice resources (Target Groups, Service Networks) are still being created by AWS

**Normal Behavior:**
- **0-2 min**: Target Groups created
- **2-5 min**: Service Network creation  
- **5-10 min**: Full deployment complete

**Monitoring Commands:**
```bash
# Monitor Gateway status
kubectl get gateway <gateway-name> -w

# Check VPC Lattice service networks
aws vpc-lattice list-service-networks --region $AWS_REGION

# Check target groups
aws vpc-lattice list-target-groups --region $AWS_REGION

# Monitor HTTPRoute events
kubectl get events --sort-by='.lastTimestamp' | grep httproute
```

**Resolution:** Wait 5-10 minutes for VPC Lattice infrastructure provisioning to complete. This is normal AWS resource creation time.

#### 8. Gateway Not Creating VPC Lattice Service Network
**Symptoms:**
```bash
kubectl describe gateway <gateway-name>
# Shows: Message: VPC Lattice Service Network not found, Status: False, Type: Programmed

kubectl describe httproute <route-name>
# Shows: failed ServiceManager.Upsert due to not found, Service network <gateway-name>
```

**Cause:** Gateway Controller bug - fails to create VPC Lattice Service Network automatically

**Fix - Manual Service Network Creation:**
```bash
# 1. Create VPC Lattice Service Network manually
aws vpc-lattice create-service-network --name <gateway-name> --region $AWS_REGION

# 2. Get VPC ID for association
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)

# 3. Associate Service Network with VPC
SERVICE_NETWORK_ID=$(aws vpc-lattice list-service-networks --region $AWS_REGION --query "items[?name=='<gateway-name>'].id" --output text)
aws vpc-lattice create-service-network-vpc-association --service-network-identifier $SERVICE_NETWORK_ID --vpc-identifier $VPC_ID --region $AWS_REGION

# 4. Get existing VPC Lattice service ID
SERVICE_ID=$(aws vpc-lattice list-services --region $AWS_REGION --query "items[0].id" --output text)

# 5. Associate service with service network
aws vpc-lattice create-service-network-service-association --service-network-identifier $SERVICE_NETWORK_ID --service-identifier $SERVICE_ID --region $AWS_REGION

# 6. Restart controller pods to refresh state
kubectl delete pods -n $NAMESPACE --all

# 7. Verify Gateway is now programmed
kubectl get gateway <gateway-name>
# Should show: PROGRAMMED = True
```

**Example for ecommerce-api-gateway:**
```bash
aws vpc-lattice create-service-network --name ecommerce-api-gateway --region $AWS_REGION
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
SERVICE_NETWORK_ID=$(aws vpc-lattice list-service-networks --region $AWS_REGION --query "items[?name=='ecommerce-api-gateway'].id" --output text)
aws vpc-lattice create-service-network-vpc-association --service-network-identifier $SERVICE_NETWORK_ID --vpc-identifier $VPC_ID --region $AWS_REGION
SERVICE_ID=$(aws vpc-lattice list-services --region $AWS_REGION --query "items[0].id" --output text)
aws vpc-lattice create-service-network-service-association --service-network-identifier $SERVICE_NETWORK_ID --service-identifier $SERVICE_ID --region $AWS_REGION
kubectl delete pods -n $NAMESPACE --all
```

**Root Cause:** AWS Gateway Controller has a bug where it doesn't automatically create VPC Lattice Service Networks. Manual creation allows the controller to recognize and manage resources properly.

#### 9. Deployment Not Found Error
**Symptoms:**
```bash
kubectl logs -n $NAMESPACE deployment/gateway-api-controller-aws-gateway-controller-chart -f
# Shows: error from server (NotFound): deployments.apps "gateway-api-controller-aws-gateway-controller-chart" not found
```

**Cause:** Incorrect deployment name - varies based on installation method

**Fix:**
```bash
# Check actual deployment name
kubectl get deployments -n $NAMESPACE

# Use correct deployment name (kubectl installation)
kubectl logs -n $NAMESPACE deployment/gateway-api-controller -f

# Alternative methods
kubectl logs -n $NAMESPACE -l control-plane=gateway-api-controller -f
kubectl logs -n $NAMESPACE deployment/gateway-api-controller -c manager -f
```

**Root Cause:** 
- **kubectl installation** creates: `gateway-api-controller`
- **Helm installation** would create: `gateway-api-controller-aws-gateway-controller-chart`
- Always verify actual resource names in your cluster rather than assuming from documentation.

### Monitoring Commands
```bash
# Watch all Gateway resources
kubectl get gateway,httproute,gatewayclass -w

# Monitor controller logs
kubectl logs -n $NAMESPACE deployment/gateway-api-controller -f

# Check VPC Lattice resources
aws vpc-lattice list-service-networks --region $AWS_REGION
aws vpc-lattice list-target-groups --region $AWS_REGION
```

## 📚 Understanding Each Component

### Gateway API CRDs
- **Standard CRDs**: Core Gateway API resources (Gateway, HTTPRoute, GatewayClass)
- **Experimental CRDs**: Additional resources like TLSRoute, GRPCRoute
- **Purpose**: Define Kubernetes custom resources for gateway functionality

### Gateway API Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GatewayClass  │───▶│     Gateway     │───▶│   HTTPRoute     │
│   (Template)    │    │   (Instance)    │    │    (Rules)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ AWS Controller  │    │ VPC Lattice     │    │ Backend Service │
│ (Management)    │    │ (Load Balancer) │    │ (Kubernetes)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### VPC Lattice Integration
- **Service Networks**: AWS managed service mesh
- **Target Groups**: Backend service endpoints
- **Security Groups**: Network access control for VPC Lattice

### IRSA (IAM Role for Service Account)
**IRSA** enables secure AWS API access from Kubernetes pods without storing credentials:

**Architecture:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   EKS Cluster   │    │   OIDC Provider │    │   AWS IAM Role  │
│                 │───▶│                 │───▶│                 │
│ Service Account │    │  (Trust Bridge) │    │  (Permissions)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Pod gets JWT  │    │  Token Exchange │    │  AWS API Calls  │
│     Token       │    │   (Automatic)   │    │   (Authorized)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Key Benefits:**
- **Security**: No AWS keys stored in cluster
- **Automation**: Credential rotation handled by AWS
- **Granular**: Per-service account permissions
- **Auditable**: All API calls tracked in CloudTrail

### Controller Components
- **Deployment**: Runs the AWS Gateway API Controller pods
- **Service Account**: Links to IAM role via IRSA
- **GatewayClass**: Defines which controller manages Gateway resources

## 📝 Important Notes

### Deployment Notes
- The setup script handles existing resources gracefully
- VPC Lattice resources may take 5-10 minutes to provision
- Controller requires experimental CRDs for full functionality
- Security group rules are automatically configured for VPC Lattice
- IRSA setup requires OIDC provider (created automatically if missing)

### Critical Steps That Must Be Done
1. **Environment Variables**: Controller MUST have `AWS_REGION` and `CLUSTER_NAME` environment variables
2. **Experimental CRDs**: Install v1.2.0 experimental CRDs, not just standard ones
3. **VPC Lattice Prefix Lists**: Use region-specific naming format `com.amazonaws.$AWS_REGION.vpc-lattice`
4. **kubectl Installation**: Use kubectl method, not Helm (chart not available in EKS repo)

### Cost Considerations
- VPC Lattice charges for Service Networks and data processing
- Target Groups have hourly charges
- Review [VPC Lattice Pricing](https://aws.amazon.com/vpc-lattice/pricing/) before deployment

### Security Best Practices
- Use least-privilege IAM policies
- Regularly rotate AWS credentials
- Monitor VPC Lattice access logs
- Review security group rules periodically

### Production Readiness
- Test in non-production environment first
- Plan for backup and disaster recovery
- Set up monitoring and alerting
- Document your specific configuration

---

**This manual approach helps you understand each component and step in the AWS Gateway API Controller deployment process.**
