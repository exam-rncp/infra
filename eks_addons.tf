# ################################################################################
# # EKS Blueprints Addons
# ################################################################################

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.cluster_name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = merge(local.tags, {
    Driver = "true"
  })

  depends_on = [module.eks]
}

module "acm" {
  source      = "terraform-aws-modules/acm/aws"
  version     = "~> 4.0"
  domain_name = local.domain_name
  zone_id     = data.cloudflare_zone.this.id
  subject_alternative_names = [
    "*.app.${local.domain_name}"
  ]
  create_route53_records  = false
  validation_method       = "DNS"
  wait_for_validation     = true
  validation_record_fqdns = cloudflare_record.validation[*].hostname
  tags = merge(local.tags, {
    Name     = "${var.project}-${var.environment}-backend-validation"
    Provider = "cloudflare"
  })

  depends_on = [module.eks, module.vpc]
}

resource "cloudflare_record" "validation" {
  count           = length(module.acm.distinct_domain_names)
  zone_id         = data.cloudflare_zone.this.id
  name            = element(module.acm.validation_domains, count.index)["resource_record_name"]
  type            = element(module.acm.validation_domains, count.index)["resource_record_type"]
  value           = trimsuffix(element(module.acm.validation_domains, count.index)["resource_record_value"], ".")
  ttl             = 60
  proxied         = false
  allow_overwrite = true
}

data "cloudflare_zone" "this" {
  name = local.domain_name
}

module "velero_backup_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "exam-"
  # Allow deletion of non-empty bucket
  # NOTE: This is enabled for example usage only, you should not enable this for production workloads
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  acl = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    status     = true
    mfa_delete = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(local.tags, {
    Driver = "true"
  })

  depends_on = [module.eks, module.vpc]
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.18"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
    coredns = {
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_argocd = true
  argocd = {
    name       = "argocd"
    version    = "7.6.12"
    repository = "https://argoproj.github.io/argo-helm"
    namespace  = "argocd"
    values     = [file("./argocd.yaml")]

    set = [{
      name  = "server.ingress.annotations.nlb\\.ingress\\.kubernetes\\.io/certificate-arn"
      value = module.acm.acm_certificate_arn
      type  = "string"
    }]
  }

  enable_aws_cloudwatch_metrics = true
  enable_cluster_autoscaler     = true

  enable_ingress_nginx = true
  ingress_nginx = {
    name          = "ingress-nginx"
    chart_version = "4.11.3"
    repository    = "https://kubernetes.github.io/ingress-nginx"
    namespace     = "ingress-nginx"
    values        = [file("./ingress_controller.yaml")]

    set = [{
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = module.acm.acm_certificate_arn
      type  = "string"
    }]
  }

  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    name          = "kube-prometheus-stack"
    chart_version = "65.5.1"
    repository    = "https://prometheus-community.github.io/helm-charts"
    namespace     = "prometheus"
    values        = [file("./prometheus.yaml")]

    set = [{
      name  = "alertmanager.ingress.annotations.nlb\\.ingress\\.kubernetes\\.io/certificate-arn"
      value = module.acm.acm_certificate_arn
      type  = "string"
      },
      {
        name  = "prometheus.ingress.annotations.nlb\\.ingress\\.kubernetes\\.io/certificate-arn"
        value = module.acm.acm_certificate_arn
        type  = "string"
      },
      {
        name  = "grafana.ingress.annotations.nlb\\.ingress\\.kubernetes\\.io/certificate-arn"
        value = module.acm.acm_certificate_arn
        type  = "string"
    }]
  }

  enable_velero = true
  ## An S3 Bucket ARN is required. This can be declared with or without a Prefix.
  velero = {
    s3_backup_location = "${module.velero_backup_s3_bucket.s3_bucket_arn}/backups"
    values = [
      # https://github.com/vmware-tanzu/helm-charts/issues/550#issuecomment-1959933230
      <<-EOT
        kubectl:
          image:
            tag: 1.29.2-debian-11-r5
      EOT
    ]
  }

  depends_on = [module.eks]
}