# Create the instance firewall rules inside the VPC selected in terraform.tfvars.
resource "aws_security_group" "web" {
  name_prefix = "remote-exec-web-"
  description = "SSH and application access for the student"
  vpc_id      = var.VPC_ID

  # Allow SSH connections on TCP port 22 only from the public IP in terraform.tfvars.
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.SSH_CIDR]
  }

  # Allow a future Python application on TCP port 5001 only from that same IP.
  ingress {
    description = "Python application"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [var.SSH_CIDR]
  }

  # Allow outbound IPv4 traffic for package downloads, updates and container images.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
