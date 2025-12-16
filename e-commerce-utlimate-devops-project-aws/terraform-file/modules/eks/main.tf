module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.subnet_ids

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    # Core addons
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    
    # Storage addons
    aws-ebs-csi-driver     = {}
    aws-efs-csi-driver     = {}
    
    # Observability addons
    metrics-server         = {}
    amazon-cloudwatch-observability = {}
    
    # Additional useful addons
    aws-secrets-store-csi-driver-provider = {}
  }

  eks_managed_node_groups = var.node_groups

  # Ensure EBS CSI driver has required IAM permissions
  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  tags = var.tags
}
