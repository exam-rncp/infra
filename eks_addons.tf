# ################################################################################
# # EKS Blueprints Addons
# ################################################################################

# resource "aws_security_group" "ingress_nginx_external" {
#   name        = "ingress-nginx-external"
#   description = "Allow public HTTP and HTTPS traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # modify to your requirements
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # modify to your requirements
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(var.default_tags, {
#     EKS_Addon = "true"
#   })
# }

# data "kubernetes_namespace" "existing_ns" {
#   metadata {
#     name = "cert-manager"
#   }

#   depends_on = [module.eks]
# }

# # Conditional namespace creation
# resource "kubernetes_namespace" "cert_manager" {
#   count = data.kubernetes_namespace.existing_ns.metadata[0].name != "cert-manager" ? 1 : 0

#   metadata {
#     name = "cert-manager"
#   }
# }

# module "ebs_csi_driver_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~> 5.20"

#   role_name_prefix = "${local.cluster_name}-ebs-csi-driver-"

#   attach_ebs_csi_policy = true

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }

#   tags = merge(var.default_tags, {
#     Driver = "true"
#   })
# }

# module "velero_backup_s3_bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "~> 3.0"

#   bucket_prefix = "${var.project}-"

#   # Allow deletion of non-empty bucket
#   # NOTE: This is enabled for example usage only, you should not enable this for production workloads
#   force_destroy = true

#   attach_deny_insecure_transport_policy = true
#   attach_require_latest_tls_policy      = true

#   acl = "private"

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   control_object_ownership = true
#   object_ownership         = "BucketOwnerPreferred"

#   versioning = {
#     status     = true
#     mfa_delete = false
#   }

#   server_side_encryption_configuration = {
#     rule = {
#       apply_server_side_encryption_by_default = {
#         sse_algorithm = "AES256"
#       }
#     }
#   }

#   tags = merge(var.default_tags, {
#     EKS_Addon = "true"
#   })
# }

# module "eks_blueprints_addons" {
#   source  = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.16"

#   cluster_name      = module.eks.cluster_name
#   cluster_endpoint  = module.eks.cluster_endpoint
#   cluster_version   = module.eks.cluster_version
#   oidc_provider_arn = module.eks.oidc_provider_arn

#   eks_addons = {
#     aws-ebs-csi-driver = {
#       most_recent              = true
#       service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
#     }
#     coredns = {
#       most_recent = true

#       timeouts = {
#         create = "25m"
#         delete = "10m"
#       }
#     }
#     vpc-cni = {
#       most_recent = true
#     }
#     kube-proxy = {}
#   }


#   enable_argocd                                = true
#   enable_aws_cloudwatch_metrics                = true
#   enable_aws_privateca_issuer                  = true
#   enable_cluster_autoscaler                    = true
#   enable_secrets_store_csi_driver              = true
#   enable_secrets_store_csi_driver_provider_aws = true

#   enable_external_dns = true
#   external_dns_route53_zone_arns = [
#     "arn:aws:route53:::hostedzone/*",
#   ]

#   enable_external_secrets = true
#   enable_ingress_nginx    = true
#   ingress_nginx = {
#     values = [
#       <<-EOT
#       controller:
#         service:
#           annotations:
#             service.beta.kubernetes.io/aws-load-balancer-security-groups: ${aws_security_group.ingress_nginx_external.id}
#             service.beta.kubernetes.io/aws-load-balancer-manage-backend-security-group-rules: true
#       EOT
#     ]
#   }

#   # Wait for all Cert-manager related resources to be ready
#   enable_cert_manager = true
#   cert_manager = {
#     wait = true
#   }

#   # Turn off mutation webhook for services to avoid ordering issue
#   enable_aws_load_balancer_controller = true
#   aws_load_balancer_controller = {
#     set = [{
#       name  = "enableServiceMutatorWebhook"
#       value = "false"
#     }]
#   }

#   enable_velero = true
#   ## An S3 Bucket ARN is required. This can be declared with or without a Prefix.
#   velero = {
#     s3_backup_location = "${module.velero_backup_s3_bucket.s3_bucket_arn}/backups"
#     values = [
#       # https://github.com/vmware-tanzu/helm-charts/issues/550#issuecomment-1959933230
#       <<-EOT
#         kubectl:
#           image:
#             tag: 1.29.2-debian-11-r5
#       EOT
#     ]
#   }

#   tags = merge(var.default_tags, {
#     EKS_Addon = "true"
#   })
# }
