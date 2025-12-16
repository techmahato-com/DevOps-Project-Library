# 🚀 Quick Start Guide - Three-Tier VPC

Get your three-tier VPC infrastructure up and running in minutes!

## ⚡ One-Command Setup

```bash
# Clone and setup
git clone <repository-url>
cd three-tier-vpc-architecture
./scripts/setup.sh
```

## 🎯 Deploy in 3 Steps

### Step 1: Setup (One-time)
```bash
make setup
```

### Step 2: Plan Deployment
```bash
# Development
make plan-dev

# Production
make plan-prod
```

### Step 3: Deploy
```bash
# Development
make deploy-dev

# Production
make deploy-prod
```

## 📋 What Gets Created

### Development Environment (21 Resources)
- ✅ VPC (10.0.0.0/16)
- ✅ 6 Subnets (2 public, 2 private, 2 database)
- ✅ 1 Internet Gateway
- ✅ 1 NAT Gateway (cost-optimized)
- ✅ 3 Route Tables + Associations
- ✅ 1 Database Subnet Group
- ✅ Comprehensive Tagging

### Production Environment
- ✅ VPC (10.2.0.0/16) - Different CIDR
- ✅ 2 NAT Gateways (high availability)
- ✅ VPC Flow Logs enabled
- ✅ Production-grade tagging

## 🛠️ Available Commands

### Quick Commands
```bash
make help                    # Show all options
make setup                   # Initial setup
make deploy-dev             # Deploy development
make deploy-prod            # Deploy production
make destroy-dev            # Destroy development
make outputs                # Show infrastructure outputs
```

### Script Commands
```bash
./scripts/deploy.sh dev --plan-only      # Plan only
./scripts/deploy.sh dev --auto-approve   # Skip confirmations
./scripts/destroy.sh dev                 # Destroy environment
```

## 🔧 Customization

### Environment Variables
Edit `environments/dev.tfvars`:
```hcl
vpc_cidr = "10.0.0.0/16"
single_nat_gateway = true    # Cost optimization
enable_flow_log = false      # Optional for dev
```

### Production Settings
Edit `environments/prod.tfvars`:
```hcl
vpc_cidr = "10.2.0.0/16"
single_nat_gateway = false   # High availability
enable_flow_log = true       # Required for production
```

## 🚨 Important Notes

### CIDR Planning
- Dev: `10.0.0.0/16`
- Staging: `10.1.0.0/16`
- Prod: `10.2.0.0/16`

### Cost Optimization
- Dev uses single NAT Gateway
- Prod uses multiple NAT Gateways for HA

### Security
- Database subnets have no internet access
- Private subnets route through NAT Gateway
- Public subnets have direct internet access

## 🆘 Troubleshooting

### Common Issues
```bash
# AWS credentials not configured
aws configure

# Terraform not initialized
terraform init

# Clean and restart
make clean
make setup
```

### Validation
```bash
# Check configuration
terraform validate

# Check AWS access
aws sts get-caller-identity

# Check plan
./scripts/deploy.sh dev --plan-only
```

## 📊 Expected Costs (Approximate)

### Development
- NAT Gateway: ~$32/month
- VPC: Free
- Total: ~$35/month

### Production
- NAT Gateways (2): ~$64/month
- VPC Flow Logs: ~$5/month
- Total: ~$70/month

## 🎉 Success Indicators

After deployment, you should see:
- ✅ 21 resources created
- ✅ VPC with proper CIDR
- ✅ Subnets across 2 AZs
- ✅ Working internet connectivity
- ✅ Proper route table associations
    
## 📞 Support

If you encounter issues:
1. Check the main README.md
2. Review Terraform logs
3. Validate AWS permissions
4. Check CIDR conflicts

---

**Ready to deploy? Run `make setup && make deploy-dev`** 🚀
