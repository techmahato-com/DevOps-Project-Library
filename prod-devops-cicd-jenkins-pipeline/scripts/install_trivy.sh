#!/bin/bash
# Install Trivy vulnerability scanner on Amazon Linux 2023
set -euo pipefail

TRIVY_VERSION="${1:-0.58.1}"

echo "Installing Trivy ${TRIVY_VERSION}..."
rpm -ivh --replacepkgs \
  "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.rpm"

trivy --version
echo "Trivy installed successfully."
