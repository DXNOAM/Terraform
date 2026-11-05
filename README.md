# Terraform EC2 and Docker

Creates the Linux EC2 instance `builder` in `us-east-1`, using the existing VPC selected by `VPC_ID` in `terraform.tfvars`. The default instance type is `t3.micro`, configurable in `terraform.tfvars`. Docker and Compose are installed automatically through `remote-exec`.

## Prerequisites

- Terraform 1.5 or later, below version 2.0, and OpenSSH.
- Bash on Linux/WSL or Git Bash on Windows for the `.sh` scripts.
- Valid AWS credentials with permission to manage EC2, key pairs and security groups.
- Internet access for Terraform providers, Ubuntu packages and container images.

Run all commands from this project folder. Run Terraform in the same terminal where you set your AWS credentials. PowerShell examples require version 7.1 or later.

## Assignment coverage

| Requirement | Implementation | Evidence after deployment |
| --- | --- | --- |
| Linux EC2 named `builder` in `us-east-1` | `resources.tf`, `vars.tf`, `provider.tf` | EC2 instance details; type matches `INSTANCE_TYPE` |
| Existing VPC and a public subnet | `security.tf`, `terraform.tfvars`, public IP enabled in `resources.tf` | Subnet belongs to the required VPC; default route points to an Internet Gateway |
| Local SSH key pair and public key registered in AWS | `generate_ssh_key.sh`, `resources.tf` | Successful SSH login; private key stays local |
| TCP 22 and 5001 from the student's IP; all IPv4 outbound traffic | `security.tf` | Security group inbound and outbound rules |
| Public IP, SSH command, private key path, security group ID and key name | Outputs in `resources.tf` | `terraform output` |
| Automatic Docker and Compose installation through `remote-exec` | `resources.tf`, `user-data.sh` | Successful apply, versions, active Docker service and `hello-world` without sudo |
| Successful Terraform plan and apply | Commands below | Saved output or screenshots |

## Files to publish on GitHub

Commit the four `.tf` source files, the two `.sh` scripts, `README.md`, `terraform.tfvars.example`, `.gitignore` and `.terraform.lock.hcl`. The lock file pins the selected AWS provider version.

Keep `terraform.tfvars`, `ssh/`, state files, state backups and saved plans (`*.tfplan`) local; `.gitignore` excludes them. `.terraform/` is a generated provider cache that `terraform init` can recreate; it is also ignored. Keep your current state and its backup while resources exist so Terraform can manage them.

## 1. Set your values

Create your local `terraform.tfvars` from the committed `terraform.tfvars.example` template. These commands preserve an existing `terraform.tfvars`.

In **Bash, WSL or Git Bash**:

```bash
# Copy the template only when local configuration does not already exist.
if [ ! -f terraform.tfvars ]; then
  cp terraform.tfvars.example terraform.tfvars
fi
```

In **PowerShell**:

```powershell
# Copy the template only when local configuration does not already exist.
if (-not (Test-Path terraform.tfvars)) {
  Copy-Item terraform.tfvars.example terraform.tfvars
}
```

Commit `terraform.tfvars.example` to GitHub so readers can see the required settings. Keep your local `terraform.tfvars` ignored. Replace all placeholders in `terraform.tfvars` before deployment.

Edit `terraform.tfvars`:
- `VPC_ID`: an existing VPC in the configured `AWS_REGION` (`us-east-1` by default in `vars.tf`).
- `SUBNET_ID`: an existing public subnet belonging to `VPC_ID` in the same region. Check its route table for `0.0.0.0/0` pointing to an Internet Gateway (`igw-...`).
- `SSH_CIDR`: the public IPv4 address of the computer running Terraform, followed by `/32`.
- `INSTANCE_TYPE`: defaults to `t3.micro`; choose a type marked Free tier eligible for your account.

When changing `VPC_ID`, update `SUBNET_ID` to a subnet in that VPC. Both must be in the configured AWS region. Changing the VPC or subnet may replace existing resources; review `terraform plan` before applying.

Terraform automatically loads `terraform.tfvars` for the root module. `vars.tf` declares the variables, their types, defaults and validation rules; `terraform.tfvars` supplies your local values. Use Terraform assignment syntax with double-quoted strings. Normal `terraform plan` and `terraform apply` commands load the values without extra flags.

Free Tier eligibility and limits depend on your AWS account. Check the [AWS Free Tier documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html) and your EC2 console before deploying. AWS credentials are configured separately from `terraform.tfvars`.

Choose the credential commands for your terminal. In **Bash, WSL or Git Bash**:

```bash
# Read the course credentials without placing secret values in command history.
read -r -p 'AWS access key ID: ' AWS_ACCESS_KEY_ID
read -r -s -p 'AWS secret access key: ' AWS_SECRET_ACCESS_KEY
printf '\n'
read -r -s -p 'AWS session token, if provided: ' AWS_SESSION_TOKEN
printf '\n'

# Make these credentials available to Terraform in this terminal.
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

In **PowerShell 7.1 or later**:

```powershell
# Set the course credentials for this terminal session.
$env:AWS_ACCESS_KEY_ID = Read-Host 'AWS access key ID'
$env:AWS_SECRET_ACCESS_KEY = Read-Host 'AWS secret access key' -MaskInput
$env:AWS_SESSION_TOKEN = Read-Host 'AWS session token, if provided' -MaskInput
```

Temporary credentials require the session token. Leave it empty only if none was provided. Do not put credentials in project files. Repeat this step when opening a new terminal or when temporary credentials expire.

## 2. Prepare the SSH key

In Bash, WSL or Git Bash, from this folder:

```bash
# Create the SSH key pair or reuse the existing local keys.
bash generate_ssh_key.sh
```

The script creates `ssh/terraform-key` and `ssh/terraform-key.pub`. It reuses an existing private key and restores its public key if missing. New keys have an empty passphrase for automated SSH, with access restricted to your user. Terraform registers only the public key with AWS and uses the private key for the SSH connection.

## 3. Deploy

In your terminal with AWS credentials, from this folder:

```bash
# Download the required Terraform provider.
terraform init
# Check configuration syntax and consistency.
terraform validate
# Review the proposed infrastructure changes.
terraform plan
# Create resources and wait for automatic Docker installation and verification.
terraform apply
# Display the public IP, SSH command, key path, security group ID and key name.
terraform output
```

Review the plan before typing `yes`. Terraform executes `user-data.sh` through an inline `remote-exec` command. It waits for cloud-init, installs Docker and Compose, starts Docker, adds `ubuntu` to the Docker group, and runs verification commands as that user. Installation or verification errors fail `apply`.

If SSH times out, check `SSH_CIDR`, the public subnet route and network firewall. If installation fails, fix the reported problem and review a new plan; Terraform may propose replacing the instance.

## 4. Verify and collect evidence

In the AWS console, select `us-east-1` and open **EC2 > Instances > builder**. Check:
- Instance state is `Running` and status checks have passed.
- Instance type matches `terraform.tfvars`, VPC matches `VPC_ID` in `terraform.tfvars`, and a public IPv4 address is assigned.
- The attached security group allows inbound TCP 22 and 5001 from `SSH_CIDR`, and all IPv4 outbound traffic.

From the local project folder, print the SSH command:

```bash
# Print the command to connect using this project's private key.
terraform output -raw connection-string
```

Copy and run the displayed command. On the Ubuntu instance, run these checks without `sudo`:

```bash
# Check installed versions, confirm the service is active and run a test container.
docker --version
docker compose version
systemctl is-active docker
docker run --rm hello-world
```

Expect version numbers, `active`, and `Hello from Docker!`. The test container exits and is removed afterward. Port 5001 is prepared for a future Python application; this project installs the Docker host.

Save screenshots or logs of plan/apply, SSH access, the Docker checks, instance details, security group rules and Terraform outputs. Do not submit private keys, credentials or state files. `.gitignore` excludes local `terraform.tfvars`, keys, provider cache, plans and state files from Git.

## 5. Remove the resources

Keep the state files and SSH keys while the AWS resources exist. In the same project folder, with valid AWS credentials:

```bash
# Review and delete the AWS resources managed by this project.
terraform destroy
```

Review the destroy plan and type `yes`. The existing VPC and subnet are preserved. Local SSH keys remain on your computer. Verify in the AWS console that the instance has terminated.
