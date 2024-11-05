# Check if ECR repositories already exist
data "aws_ecr_repository" "existing_repositories" {
  for_each = toset(var.repository_names)
  name     = each.value
}

# Create IAM Policy Document for ECR Push/Pull
data "aws_iam_policy_document" "push-pull-policy-document" {
  statement {
    sid    = "NewPolicy"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]

    resources = [for repo in aws_ecr_repository.ecr-repositories : repo.arn]
  }
}

# IAM Policy: Create only if the policy doesn't already exist
data "aws_iam_policy" "existing_policy" {
  name = "ECRPushPull"
}

resource "aws_iam_policy" "push-pull-policy" {
  count       = length(data.aws_iam_policy.existing_policy) == 0 ? 1 : 0
  name        = "ECRPushPull"
  description = "Allow push-pull image operations in ECR repositories"
  policy      = data.aws_iam_policy_document.push-pull-policy-document.json
}

# IAM Group Policy Attachment: Attach policy only if not already attached
data "aws_iam_group_policy_attachment" "existing_attachment" {
  for_each = toset(var.user_group)
  group    = each.value
  policy_arn = aws_iam_policy.push-pull-policy.arn
}

resource "aws_iam_group_policy_attachment" "push-pull-policy-attachment" {
  count      = length([for attachment in data.aws_iam_group_policy_attachment.existing_attachment : attachment if attachment.policy_arn == aws_iam_policy.push-pull-policy.arn]) == 0 ? 1 : 0
  group      = var.user_group
  policy_arn = aws_iam_policy.push-pull-policy.arn
}

# ECR Repository: Create repository only if it doesn't already exist
resource "aws_ecr_repository" "ecr-repositories" {
  for_each = toset(var.repository_names)

  count = length([for repo in data.aws_ecr_repository.existing_repositories : repo if repo.name == each.value]) == 0 ? 1 : 0

  name = each.value
  tags = local.tags
}

# ECR Lifecycle Policy: Apply lifecycle policy for each repository
resource "aws_ecr_lifecycle_policy" "ecr-repositories-lifecycle-policy" {
  for_each = aws_ecr_repository.ecr-repositories

  repository = each.value.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
