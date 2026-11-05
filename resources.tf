# Create the builder EC2 instance with its network, SSH key and security group.
resource "aws_instance" "example" {
  # Select the Linux image and load the instance size and subnet from terraform.tfvars.
  ami                         = var.AMIS[var.AWS_REGION]
  instance_type               = var.INSTANCE_TYPE
  subnet_id                   = var.SUBNET_ID
  associate_public_ip_address = true
  key_name                    = aws_key_pair.example.key_name
  vpc_security_group_ids      = [aws_security_group.web.id]

  # Display builder as the instance name in the AWS console.
  tags = {
    Name = "builder"
  }

  # Connect as ubuntu over SSH using the local private key for remote setup.
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = sensitive(file("${path.module}/ssh/terraform-key"))
    host        = self.public_ip
    agent       = false
    timeout     = "15m"
  }

  # Run user-data.sh over SSH and wait for installation and verification to finish.
  provisioner "remote-exec" {
    inline = ["sudo bash -e <<'DOCKER_SETUP'\n${file("${path.module}/user-data.sh")}\nDOCKER_SETUP"]
  }
}

# Register the local public key with EC2; keep the private key on this computer.
resource "aws_key_pair" "example" {
  key_name_prefix = "deployer-key-"
  public_key      = file("${path.module}/ssh/terraform-key.pub")
}

# Print the instance public IP after deployment.
output "ip" {
  value = aws_instance.example.public_ip
}

# Print the SSH command used to connect to the instance.
output "connection-string" {
  value = "ssh -i ssh/terraform-key ubuntu@${aws_instance.example.public_ip}"
}

# Print only the local private key path, without revealing its contents.
output "ssh_private_key_path" {
  value = abspath("${path.module}/ssh/terraform-key")
}

# Print the security group ID for inspection in the AWS console.
output "security_group_id" {
  value = aws_security_group.web.id
}

# Print the name of the public key pair registered in AWS.
output "ssh_key_name" {
  value = aws_key_pair.example.key_name
}
