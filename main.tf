# ============================================================
# terraform/main.tf — 入口點
# ============================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "gitops/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# ── 基礎設施 ──────────────────────────────────────────────────

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  aws_region   = var.aws_region
  environment  = var.environment
}

module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  depends_on         = [module.vpc]
}

# ── 應用平台 ──────────────────────────────────────────────────

module "harbor" {
  source          = "./modules/harbor"
  harbor_domain   = var.harbor_domain
  harbor_password = var.harbor_admin_password
  depends_on      = [module.eks]
}

module "argocd" {
  source          = "./modules/argocd"
  argocd_domain   = var.argocd_domain
  gitlab_repo_url = var.gitlab_repo_url
  depends_on      = [module.eks]
}

module "kuboard" {
  source                = "./modules/kuboard"
  kuboard_domain        = var.kuboard_domain
  gitlab_base_url       = var.gitlab_base_url
  gitlab_application_id = var.gitlab_kuboard_app_id
  gitlab_client_secret  = var.gitlab_kuboard_secret
  depends_on            = [module.eks]
}

module "elk" {
  source        = "./modules/elk"
  kibana_domain = var.kibana_domain
  depends_on    = [module.eks]
}

module "monitoring" {
  source                = "./modules/monitoring"
  grafana_domain        = var.grafana_domain
  gitlab_base_url       = var.gitlab_base_url
  gitlab_client_id      = var.gitlab_grafana_client_id
  gitlab_client_secret  = var.gitlab_grafana_client_secret
  alertmanager_email    = var.alertmanager_email
  slack_webhook_url     = var.slack_webhook_url
  depends_on            = [module.eks]
}

module "jenkins" {
  source                 = "./modules/jenkins"
  jenkins_domain         = var.jenkins_domain
  jenkins_admin_user     = var.jenkins_admin_user
  jenkins_admin_password = var.jenkins_admin_password
  jenkins_storage_size   = var.jenkins_storage_size
  depends_on             = [module.eks]
}
