# Define the supported Terraform version and required provider plugins.
terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  # Declare the plugins Terraform needs to manage this project.
  required_providers {
    # Download the official AWS provider and use a compatible version.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure AWS operations to run in the region selected in vars.tf.
provider "aws" {
  region = var.AWS_REGION
}
