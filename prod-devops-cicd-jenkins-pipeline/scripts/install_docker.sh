#!/bin/bash
# Install Docker on Amazon Linux 2023
set -euo pipefail

dnf install -y docker
systemctl enable docker
systemctl start docker

# Add current user and ec2-user to docker group
usermod -aG docker ec2-user || true
usermod -aG docker "${SUDO_USER:-$(whoami)}" || true

docker --version
echo "Docker installed successfully."
