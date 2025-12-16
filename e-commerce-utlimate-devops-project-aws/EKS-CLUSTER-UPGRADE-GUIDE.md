# EKS Cluster Zero-Downtime Upgrade Guide

## Overview
This guide provides step-by-step instructions for upgrading EKS clusters without downtime, based on real-world experience upgrading from Kubernetes 1.32 to 1.33.

## Prerequisites
- AWS CLI configured with appropriate permissions
- kubectl configured for your cluster
- Terraform installed (if using IaC)
- Backup of critical workloads

## Pre-Upgrade Checklist

### 1. Check Current Cluster Status
```bash
# Verify cluster version and status
aws eks describe-cluster --name <cluster-name> --region <region>

# Check node groups
aws eks list-nodegroups --cluster-name <cluster-name> --region <region>

# Verify all pods are running
kubectl get pods -A
```

### 2. Review Kubernetes Version Compatibility
- Check [EKS Kubernetes versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
- Review [Kubernetes changelog](https://kubernetes.io/releases/) for breaking changes
- Verify addon compatibility with target version

### 3. Backup Critical Resources
```bash
# Backup cluster configuration
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Export important ConfigMaps and Secrets
kubectl get configmaps --all-namespaces -o yaml > configmaps-backup.yaml
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml
```

## Upgrade Process (Zero Downtime)

### Phase 1: Control Plane Upgrade

#### Step 1: Update Terraform Configuration
```hcl
# In your EKS module or main.tf
cluster_version = "1.33"  # Update to target version
```

#### Step 2: Apply Control Plane Upgrade
```bash
# Plan the upgrade
terraform plan -var-file="environments/dev.tfvars"

# Apply control plane upgrade (takes 10-15 minutes)
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

#### Step 3: Verify Control Plane
```bash
# Check cluster version
aws eks describe-cluster --name <cluster-name> --query 'cluster.version'

# Verify API server is responsive
kubectl get nodes
kubectl get pods -A
```

### Phase 2: Node Groups Upgrade

#### Step 1: Prepare for Node Replacement
```bash
# Check current node AMI types
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>

# Ensure PodDisruptionBudgets are configured
kubectl get pdb --all-namespaces
```

#### Step 2: Update Node Group Configuration
```hcl
# In your Terraform configuration
node_groups = {
  application = {
    ami_type = "AL2023_x86_64_STANDARD"  # Use latest AMI
    # ... other configuration
  }
}
```

#### Step 3: Rolling Node Group Update
```bash
# Apply node group updates (Terraform handles rolling updates)
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

#### Step 4: Monitor Node Replacement
```bash
# Watch nodes being replaced
kubectl get nodes -w

# Monitor pod rescheduling
kubectl get pods -A -w

# Check node readiness
kubectl describe nodes
```

### Phase 3: Addon Upgrades

#### Step 1: Check Addon Compatibility
```bash
# List current addons
aws eks list-addons --cluster-name <cluster-name>

# Check available versions for target Kubernetes version
aws eks describe-addon-versions --addon-name <addon-name> --kubernetes-version 1.33
```

#### Step 2: Update Addons (Automatic with Terraform)
```bash
# Addons are automatically updated when cluster version changes
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

#### Step 3: Verify Addon Status
```bash
# Check addon status
aws eks describe-addon --cluster-name <cluster-name> --addon-name <addon-name>

# Verify addon pods
kubectl get pods -n kube-system
kubectl get pods -n amazon-cloudwatch
```

## Common Issues and Solutions

### Issue 1: Addon Installation Timeout
**Problem**: Addons stuck in DEGRADED state due to scheduling issues

**Solution**:
```bash
# Check for node taints preventing system pod scheduling
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Temporarily remove taints if all nodes are tainted
kubectl taint node <node-name> <taint-key>:NoSchedule-

# Or ensure at least one node group has no taints in Terraform
```

### Issue 2: EBS CSI Driver Permission Issues
**Problem**: EBS CSI controller crashes with IAM permission errors

**Solution**:
```bash
# Add EBS CSI policy to node group roles
aws iam attach-role-policy \
  --role-name <node-group-role-name> \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
```

**Terraform Prevention**:
```hcl
eks_managed_node_group_defaults = {
  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
}
```

### Issue 3: Pod Scheduling Failures
**Problem**: Pods can't schedule due to resource constraints or taints

**Solution**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
kubectl describe nodes

# Remove problematic taints
kubectl taint node <node-name> <taint-key>-
```

## Best Practices for Zero-Downtime Upgrades

### 1. Node Group Configuration
```hcl
# Avoid taints on all node groups - keep at least one clean for system pods
node_groups = {
  application = {
    # No taints - allows system pods
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 4
    desired_size   = 2
  }
  
  backend = {
    # Optional: Use node selectors instead of taints
    labels = {
      workload-type = "backend"
    }
  }
}
```

### 2. Pod Disruption Budgets
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: my-app
```

### 3. Health Checks and Readiness Probes
```yaml
spec:
  containers:
  - name: app
    readinessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
```

### 4. Resource Requests and Limits
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

## Upgrade Timeline

| Phase | Duration | Downtime |
|-------|----------|----------|
| Control Plane | 10-15 min | None |
| Node Groups | 15-30 min | None* |
| Addons | 5-10 min | None |
| **Total** | **30-55 min** | **Zero** |

*No downtime if PodDisruptionBudgets and multiple replicas are configured

## Post-Upgrade Verification

### 1. Cluster Health Check
```bash
# Verify cluster version
kubectl version --short

# Check all nodes are ready
kubectl get nodes

# Verify all system pods are running
kubectl get pods -n kube-system
kubectl get pods -n amazon-cloudwatch
```

### 2. Application Health Check
```bash
# Check application pods
kubectl get pods --all-namespaces

# Verify services are accessible
kubectl get svc --all-namespaces

# Test application endpoints
curl -f http://<service-endpoint>/health
```

### 3. Addon Verification
```bash
# Check addon status
aws eks list-addons --cluster-name <cluster-name>

# Verify specific addon functionality
kubectl get storageclass  # EBS CSI
kubectl get csidriver     # All CSI drivers
kubectl top nodes         # Metrics server
```

## Rollback Plan

### If Control Plane Upgrade Fails
```bash
# Rollback via Terraform
terraform apply -var cluster_version="1.32" -auto-approve
```

### If Node Group Upgrade Fails
```bash
# Rollback node group configuration
terraform apply -var-file="environments/dev.tfvars" -auto-approve

# Or manually update node groups
aws eks update-nodegroup-version --cluster-name <cluster-name> --nodegroup-name <name>
```

## Maintenance Windows

### Recommended Schedule
- **Control Plane**: Any time (no downtime)
- **Node Groups**: During low traffic periods
- **Addons**: Any time (minimal impact)

### Communication Template
```
Subject: EKS Cluster Upgrade - No Expected Downtime

We will be upgrading our EKS cluster from v1.32 to v1.33 on [DATE] at [TIME].

Expected Duration: 45 minutes
Expected Downtime: None

The upgrade includes:
- Control plane upgrade (no impact)
- Rolling node replacement (no impact)
- Addon updates (minimal impact)

Applications should remain available throughout the upgrade.
```

## Troubleshooting Commands

```bash
# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node conditions
kubectl describe nodes | grep -A 5 Conditions

# Check addon logs
kubectl logs -n kube-system -l app=<addon-name>

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Describe problematic pods
kubectl describe pod <pod-name> -n <namespace>
```

## Conclusion

Following this guide ensures zero-downtime EKS cluster upgrades by:
1. Upgrading control plane first (no impact)
2. Rolling node group updates with proper PDBs
3. Automatic addon compatibility updates
4. Proper monitoring and verification

Key success factors:
- Remove node taints that prevent system pod scheduling
- Ensure proper IAM permissions for addons
- Configure PodDisruptionBudgets for applications
- Monitor the upgrade process closely

For questions or issues, refer to the troubleshooting section or AWS EKS documentation.
