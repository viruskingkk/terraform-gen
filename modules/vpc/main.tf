# ============================================================
# terraform/modules/vpc/main.tf
# ============================================================

data "aws_availability_zones" "available" {}

locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr        = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false   # HA：每個 AZ 一個 NAT GW
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # EKS 需要的 subnet tags
  public_subnet_tags = {
    "kubernetes.io/role/elb"                              = 1
    "kubernetes.io/cluster/${var.project_name}-cluster"  = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                    = 1
    "kubernetes.io/cluster/${var.project_name}-cluster"  = "shared"
  }
}

# ── Outputs ──────────────────────────────────────────────────
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}
