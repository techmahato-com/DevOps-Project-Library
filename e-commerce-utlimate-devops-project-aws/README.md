# Three-Tier VPC Architecture with EKS on AWS

A production-ready Terraform infrastructure for deploying a three-tier VPC architecture with Amazon EKS cluster, including all necessary addons and best practices.

## 🏗️ Architecture Overview

This infrastructure creates:
- **VPC**: Three-tier architecture (public, private, database subnets)
- **EKS Cluster**: Kubernetes 1.33 with managed node groups
- **Bastion Host**: Secure access to private resources
- **EKS Addons**: Storage, monitoring, and security addons
- **Security**: Proper IAM roles, security groups, and network ACLs

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl installed
- SSH key pair for bastion host access

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd terraform-file
```

### 2. Configure Variables
```bash
# Copy example variables file
cp environments/dev.tfvars.example environments/dev.tfvars

# Edit the variables file with your settings
nano environments/dev.tfvars
```

### 3. Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Deploy infrastructure
terraform apply -var-file="environments/dev.tfvars"
```

### 4. Configure kubectl
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name e-commerce-dev

# Verify cluster access
kubectl get nodes
```

## 📁 Project Structure

```
terraform-file/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars          # Default variables
├── environments/
│   ├── dev.tfvars.example    # Example development variables
│   ├── staging.tfvars        # Staging environment variables
│   └── prod.tfvars           # Production environment variables
├── modules/
│   ├── vpc/                  # VPC module
│   ├── eks/                  # EKS cluster module
│   └── bastion/              # Bastion host module
└── docs/
    └── EKS-CLUSTER-UPGRADE-GUIDE.md
```

## 🔧 Configuration

### Required Variables

Edit `environments/dev.tfvars` with your specific values:

```hcl
# Basic Configuration
project_name = "your-project"
environment  = "dev"
region      = "us-east-1"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
azs      = ["us-east-1a", "us-east-1b"]

# EKS Configuration
cluster_name    = "your-cluster-name"
cluster_version = "1.33"
```

### Optional Customizations

- **Instance Types**: Modify node group instance types based on workload
- **Scaling**: Adjust min/max/desired sizes for node groups
- **Addons**: Enable/disable specific EKS addons
- **Bastion**: Set `enable_bastion = false` if not needed

## 🏗️ Infrastructure Components

### VPC Architecture
- **Public Subnets**: Load balancers, NAT gateways, bastion host
- **Private Subnets**: EKS worker nodes, application servers
- **Database Subnets**: RDS instances, ElastiCache clusters

### EKS Cluster
- **Control Plane**: Managed by AWS, highly available
- **Node Groups**: 
  - Application nodes (web tier)
  - Backend nodes (application tier)
  - Monitoring nodes (observability)

### EKS Addons Included
- **Storage**: EBS CSI Driver, EFS CSI Driver
- **Networking**: VPC CNI, CoreDNS, Kube-proxy
- **Monitoring**: Metrics Server, CloudWatch Observability
- **Security**: Pod Identity Agent, Secrets Store CSI Driver

## 🔒 Security Features

- **IAM Roles**: Least privilege access for all components
- **Security Groups**: Restrictive network access rules
- **Encryption**: EBS volumes and EKS secrets encrypted
- **Network Isolation**: Private subnets for sensitive workloads
- **Bastion Access**: Secure SSH access to private resources

## 📊 Monitoring and Observability

- **CloudWatch**: Cluster and application metrics
- **Metrics Server**: Kubernetes resource metrics
- **Fluent Bit**: Log aggregation and forwarding
- **Container Insights**: EKS-specific monitoring

## 🔄 Upgrade Guide

See [EKS-CLUSTER-UPGRADE-GUIDE.md](./EKS-CLUSTER-UPGRADE-GUIDE.md) for detailed instructions on:
- Zero-downtime cluster upgrades
- Node group rolling updates
- Addon compatibility management
- Troubleshooting common issues

## 💰 Cost Optimization

### Included Cost-Saving Features
- **Spot Instances**: Used for monitoring node group
- **Right-sizing**: Appropriate instance types for workloads
- **Auto Shutdown**: Tags for automated resource management
- **Efficient Networking**: Single NAT gateway for cost savings

### Estimated Monthly Costs (us-east-1)
- **EKS Control Plane**: ~$73
- **Worker Nodes**: ~$150-300 (depending on usage)
- **NAT Gateway**: ~$45
- **Load Balancers**: ~$20-50
- **Total**: ~$288-468/month

## 🚨 Troubleshooting

### Common Issues

1. **Addon Installation Failures**
   ```bash
   # Check addon status
   aws eks describe-addon --cluster-name <cluster-name> --addon-name <addon-name>
   
   # Check pod scheduling
   kubectl get pods -A | grep Pending
   ```

2. **Node Group Issues**
   ```bash
   # Check node status
   kubectl get nodes
   kubectl describe nodes
   ```

3. **Permission Issues**
   ```bash
   # Verify IAM roles
   aws iam list-attached-role-policies --role-name <role-name>
   ```

### Support Resources
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Tags

`terraform` `aws` `eks` `kubernetes` `vpc` `infrastructure` `devops` `iac` `three-tier-architecture`

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the [EKS Upgrade Guide](./EKS-CLUSTER-UPGRADE-GUIDE.md)
3. Open an issue in this repository
4. Consult AWS documentation

---

**⚠️ Important Notes:**
- Always test in a development environment first
- Review and customize security groups for your use case
- Monitor costs and adjust instance types as needed
- Keep Terraform state files secure and backed up
