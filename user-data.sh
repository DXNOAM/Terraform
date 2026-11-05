#!/bin/bash
# Run setup with strict error handling and noninteractive package installation.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Wait for cloud-init to finish, allowing recoverable initialization warnings.
cloud-init status --wait || { code=$?; [ "$code" -eq 2 ] || exit "$code"; }

# Refresh package lists and install Docker and Compose, waiting for package-manager locks.
apt-get -o DPkg::Lock::Timeout=300 update
apt-get -o DPkg::Lock::Timeout=300 install -y docker.io docker-compose-v2

# Start Docker automatically and let ubuntu use it without sudo.
systemctl enable --now docker
usermod -aG docker ubuntu

# Check Docker and Compose and run a test container using ubuntu's updated group membership.
systemctl is-active --quiet docker
runuser -u ubuntu -- docker --version
runuser -u ubuntu -- docker compose version
runuser -u ubuntu -- docker run --rm hello-world
