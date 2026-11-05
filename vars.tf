# Choose the AWS region where Terraform creates the instance and security group.
variable "AWS_REGION" {
  default = "us-east-1"
}

# Store the supplied Ubuntu 24.04 image IDs for each supported AWS region.
variable "AMIS" {
  type = map(string)
  # Map each region name to its Linux image ID.
  default = {
    us-east-1 = "ami-0d6dd9e8265d48906"
    us-west-2 = "ami-08cf17e3856f70154"
    eu-west-1 = "ami-0445442ed20a2c6f8"
  }
}

# Select an existing VPC in the configured AWS region.
variable "VPC_ID" {
  type = string

  # Reject an incorrectly formatted VPC ID before deployment.
  validation {
    condition     = can(regex("^vpc-([0-9a-f]{8}|[0-9a-f]{17})$", var.VPC_ID))
    error_message = "Set VPC_ID in terraform.tfvars to an existing VPC in the configured AWS region."
  }
}

# Select a public subnet belonging to the configured VPC.
variable "SUBNET_ID" {
  type = string

  # Require a correctly formatted subnet ID.
  validation {
    condition     = can(regex("^subnet-([0-9a-f]{8}|[0-9a-f]{17})$", var.SUBNET_ID))
    error_message = "Set SUBNET_ID in terraform.tfvars to a public subnet that belongs to VPC_ID."
  }
}

# Allow inbound access from the student's public IPv4 address.
variable "SSH_CIDR" {
  type = string

  # Limit access to one valid IPv4 address with a /32 suffix.
  validation {
    condition     = can(cidrnetmask(var.SSH_CIDR)) && endswith(var.SSH_CIDR, "/32")
    error_message = "Set SSH_CIDR in terraform.tfvars to your public IPv4 address followed by /32."
  }
}

# Use t3.micro unless a different instance type is set in terraform.tfvars.
variable "INSTANCE_TYPE" {
  type    = string
  default = "t3.micro"
}
