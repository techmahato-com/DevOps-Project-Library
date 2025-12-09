module "vpc" {
  source = "../../modules/vpc"

  vpc_name        = var.vpc_name
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  tags = {
    Environment = "prod"
    Project     = "terraform-github-actions"
    ManagedBy   = "terraform"
  }
}
