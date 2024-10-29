# Infra: Terraform EC2, EKS, VPC and Sock-shop Setup

This project sets up an AWS EKS cluster within a VPC using Terraform modules. 

## Files
- `main.tf`: Orchestrates the modules for VPC and EKS.
- `variables.tf`: Defines input variables for flexibility.
- `outputs.tf`: Exposes output values.
- `providers.tf`: Configures providers, e.g., AWS.

## Usage
1. Modify `variables.tf` to fit your AWS setup.
2. Run `terraform init`.
3. Apply the changes with `terraform apply`.
