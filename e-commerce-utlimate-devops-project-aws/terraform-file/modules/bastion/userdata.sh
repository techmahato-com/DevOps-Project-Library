#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Set hostname
hostnamectl set-hostname ${hostname}
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# Install basic packages
apt-get install -y curl wget unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform

# Install Git (usually pre-installed, but ensure latest version)
apt-get install -y git

# Install additional useful tools
apt-get install -y htop tree jq vim nano

# Create welcome message
cat > /etc/motd << 'EOF'
===============================================
    Bastion Host - DevOps Tools Ready
===============================================
Installed Software:
- AWS CLI v2
- Docker & Docker Compose
- kubectl
- eksctl
- Terraform
- Git
- Additional tools: htop, tree, jq, vim

Usage:
- aws --version
- docker --version
- kubectl version --client
- eksctl version
- terraform version
- git --version

===============================================
EOF

# Clean up
apt-get autoremove -y
apt-get autoclean

# Log installation completion
echo "$(date): Bastion host setup completed" >> /var/log/userdata.log
