# Infra: Terraform EC2, EKS, VPC and Sock-shop Setup

This project sets up an AWS EKS cluster within a VPC using Terraform modules. 

## Prerequisites

- Terraform >= 0.12
- AWS CLI configured
- kubectl installed

## Setup Instructions

1. **Clone the repository:**
    ```sh
    git clone https://github.com/yourusername/infra.git
    cd infra
    ```

2. **Initialize Terraform:**
    ```sh
    terraform init
    ```

3. **Apply the Terraform configuration:**
    ```sh
    terraform apply
    ```

4. **Configure kubectl to use the new EKS cluster:**
    ```sh
    aws eks --region <your-region> update-kubeconfig --name <your-cluster-name>
    ```

5. **Deploy the Sock-shop application:**
    ```sh
    kubectl apply -f sock-shop.yaml
    ```