# ============================================================
# terraform/modules/eks/main.tf
# ============================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.29"

  vpc_id                         = var.vpc_id
  subnet_ids                     = var.private_subnet_ids
  cluster_endpoint_public_access = true

  # OIDC（供 IAM Roles for Service Accounts 使用）
  enable_irsa = true

  # EKS Managed Node Group
  eks_managed_node_groups = {
    general = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size

      disk_size = 50

      labels = {
        role = "general"
      }

      tags = {
        Environment = var.environment
      }
    }
  }

  # 預設 Addons
  cluster_addons = {
    vpc-cni            = { most_recent = true }
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }

  # Cluster Logging
  cluster_enabled_log_types = [
    "api", "audit", "authenticator",
    "controllerManager", "scheduler"
  ]
}

# ── gp3 StorageClass（設為 default）─────────────────────────
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
}

# ── Namespaces ────────────────────────────────────────────────
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(["dev", "staging", "prod", "harbor", "argocd", "kuboard", "logging", "monitoring"])

  metadata {
    name = each.key
    labels = {
      "managed-by" = "terraform"
    }
  }
}

# ── Outputs ──────────────────────────────────────────────────
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
