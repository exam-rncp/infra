#!/bin/bash

# Variables (replace these with your actual values)
REPO_NAMES=("front-end" "catalogue" "catalogue-db" "queue-master" "shipping" "payment" "user" "orders" "user-db")
USER_GROUP="ECRUsers"
AWS_REGION="your-region"
POLICY_NAME="ECRPushPull"
POLICY_ARN=""

# Function to create ECR repositories
create_repos() {
  for repo in "${REPO_NAMES[@]}"; do
    echo "Creating repository: $repo"
    aws ecr create-repository --repository-name "$repo" --region "$AWS_REGION"
  done
}

# Function to delete ECR repositories
delete_repos() {
  for repo in "${REPO_NAMES[@]}"; do
    echo "Deleting repository: $repo"
    aws ecr delete-repository --repository-name "$repo" --region "$AWS_REGION" --force
  done
}

# Function to create IAM policy for ECR push/pull operations
create_iam_policy() {
  POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NewPolicy",
      "Effect": "Allow",
      "Action": [
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
        "ecr:DeleteRepositoryPolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

  echo "Creating IAM policy for ECR push/pull operations."
  POLICY_ARN=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$POLICY_DOCUMENT" --query 'Policy.Arn' --output text)
  echo "Attaching policy to user group $USER_GROUP."
  aws iam attach-group-policy --group-name "$USER_GROUP" --policy-arn "$POLICY_ARN"
}

# Function to delete IAM policy
delete_iam_policy() {
  echo "Detaching policy from user group $USER_GROUP."
  aws iam detach-group-policy --group-name "$USER_GROUP" --policy-arn "$POLICY_ARN"

  echo "Deleting IAM policy $POLICY_NAME."
  aws iam delete-policy --policy-arn "$POLICY_ARN"
}

# Function to set ECR lifecycle policies
set_lifecycle_policies() {
  LIFECYCLE_POLICY=$(cat <<EOF
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
)

  for repo in "${REPO_NAMES[@]}"; do
    echo "Setting lifecycle policy for repository: $repo"
    aws ecr put-lifecycle-policy --repository-name "$repo" --region "$AWS_REGION" --lifecycle-policy-text "$LIFECYCLE_POLICY"
  done
}

# Apply function to create all resources
apply() {
  create_repos
  create_iam_policy
  set_lifecycle_policies
}

# Destroy function to remove all resources
destroy() {
  delete_repos
  delete_iam_policy
}

# Main script logic
if [ "$1" == "apply" ]; then
  apply
elif [ "$1" == "destroy" ]; then
  destroy
else
  echo "Usage: $0 {apply|destroy}"
fi
