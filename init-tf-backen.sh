#!/bin/bash

# Exit immediately if any command exits with a non-zero status
set -e

# Initialize variables
USER_NAME="f3linadmin"
AWS_REGION="eu-central-1"
TABLE_NAME="tf-lock-table"
S3_BUCKET_NAME=""
DELETE_MODE=false

# Ensure AWS CLI and jq are installed
if ! command -v aws &>/dev/null || ! command -v jq &>/dev/null; then
  echo "Error: Both AWS CLI and jq must be installed."
  exit 1
fi

# Check AWS CLI authentication
if ! aws sts get-caller-identity &>/dev/null; then
  echo "Error: AWS CLI is not authenticated. Please configure your credentials."
  exit 1
fi

# Function to check for the exit status of each command
check_exit_status() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# Parse options
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -d|--delete)
      DELETE_MODE=true
      ;;
    -b|--bucket)
      S3_BUCKET_NAME="$2"
      shift
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1
      ;;
  esac
  shift
done

# Use default bucket name if not provided
S3_BUCKET_NAME=${S3_BUCKET_NAME:-"tf-remote-state-$(date +%s)"}

# Functions to create and delete resources
create_resources() {
  echo "Creating resources with bucket: $S3_BUCKET_NAME"

  # Extract User ARN
  USER_ARN=$(aws iam get-user --user-name "$USER_NAME" --query 'User.Arn' --output text)
  check_exit_status "Failed to retrieve user ARN."

  # Create S3 Bucket
  echo "Creating S3 bucket: $S3_BUCKET_NAME..."
  aws s3 mb "s3://$S3_BUCKET_NAME" --region "$AWS_REGION"
  check_exit_status "Failed to create S3 bucket."

  # Enable Versioning for S3 Bucket
  echo "Enabling versioning on S3 bucket..."
  aws s3api put-bucket-versioning --bucket "$S3_BUCKET_NAME" --versioning-configuration Status=Enabled
  check_exit_status "Failed to enable versioning on the S3 bucket."

  # Create DynamoDB Table
  echo "Creating DynamoDB table: $TABLE_NAME..."
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region "$AWS_REGION" &>/dev/null
  check_exit_status "Failed to create DynamoDB table."

  # Apply S3 bucket policy
  echo "Setting bucket policy..."
  sed -e "s|RESOURCE|arn:aws:s3:::$S3_BUCKET_NAME|g" \
      -e "s|KEY|terraform.tfstate|g" \
      -e "s|ARN|$USER_ARN|g" "$(dirname "$0")/s3_policy.json" > /tmp/new-policy.json
  check_exit_status "Failed to generate S3 bucket policy."

  aws s3api put-bucket-policy --bucket "$S3_BUCKET_NAME" --policy file:///tmp/new-policy.json
  check_exit_status "Failed to apply policy to the S3 bucket."
  rm /tmp/new-policy.json

  # Summary output
  echo -e "\nAWS S3 and DynamoDB remote backend setup complete!"
  echo "S3 Bucket: $S3_BUCKET_NAME (Versioning enabled)"
  echo "DynamoDB Table: $TABLE_NAME"
  echo "Resources created in AWS region: $AWS_REGION"
}

delete_resources() {
  echo "Deleting resources for bucket: $S3_BUCKET_NAME"

  # Delete all objects in the S3 bucket and the bucket itself
  if aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
    echo "Emptying and deleting S3 bucket: $S3_BUCKET_NAME..."
    aws s3 rm "s3://$S3_BUCKET_NAME" --recursive
    aws s3api delete-bucket --bucket "$S3_BUCKET_NAME" --region "$AWS_REGION"
    check_exit_status "Failed to delete S3 bucket."
  else
    echo "S3 bucket $S3_BUCKET_NAME does not exist."
  fi

  # Delete the DynamoDB table if it exists
  if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" &>/dev/null; then
    echo "Deleting DynamoDB table: $TABLE_NAME..."
    aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$AWS_REGION"
    check_exit_status "Failed to delete DynamoDB table."
  else
    echo "DynamoDB table $TABLE_NAME does not exist."
  fi

  echo "Resources deleted successfully."
}

# Execute create or delete based on DELETE_MODE
if [ "$DELETE_MODE" = true ]; then
  delete_resources
else
  create_resources
fi
