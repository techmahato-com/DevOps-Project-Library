#!/bin/bash
# Install OWASP Dependency Check on Amazon Linux 2023
set -euo pipefail

OWASP_VERSION="${1:-10.0.2}"
INSTALL_DIR="/opt/dependency-check"
URL="https://github.com/jeremylong/DependencyCheck/releases/download/v${OWASP_VERSION}/dependency-check-${OWASP_VERSION}-release.zip"

echo "Installing OWASP Dependency Check ${OWASP_VERSION}..."
dnf install -y unzip java-17-amazon-corretto-headless

cd /opt
curl -fsSL "$URL" -o dependency-check.zip
unzip -qo dependency-check.zip
rm -f dependency-check.zip
ln -sfn "$INSTALL_DIR" /opt/owasp-dc
chmod +x "$INSTALL_DIR/bin/dependency-check.sh"

echo 'export PATH=$PATH:/opt/owasp-dc/bin' > /etc/profile.d/owasp.sh
chmod +x /etc/profile.d/owasp.sh

echo "OWASP Dependency Check ${OWASP_VERSION} installed at ${INSTALL_DIR}"
