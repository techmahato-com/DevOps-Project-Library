#!/bin/bash
# =============================================================================
# Supplemental Tools Install Script
# Run this on Jenkins or agent nodes to install/upgrade individual tools.
# Idempotent: safe to re-run.
# =============================================================================
set -euo pipefail

# ─── Maven ───────────────────────────────────────────────────────────────────
install_maven() {
  local version="${1:-3.9.6}"
  local url="https://archive.apache.org/dist/maven/maven-3/${version}/binaries/apache-maven-${version}-bin.tar.gz"

  echo "Installing Maven ${version}..."
  cd /opt
  curl -fsSL "$url" -o maven.tar.gz
  tar -xzf maven.tar.gz && rm -f maven.tar.gz
  ln -sfn "/opt/apache-maven-${version}" /opt/maven

  cat > /etc/profile.d/maven.sh << EOF
export M2_HOME=/opt/maven
export PATH=\$PATH:\$M2_HOME/bin
EOF
  chmod +x /etc/profile.d/maven.sh
  echo "Maven $(source /etc/profile.d/maven.sh && mvn -version 2>&1 | head -1) installed."
}

# ─── Trivy ───────────────────────────────────────────────────────────────────
install_trivy() {
  local version="${1:-0.58.1}"
  echo "Installing Trivy ${version}..."
  rpm -ivh --replacepkgs \
    "https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_Linux-64bit.rpm"
  trivy --version
}

# ─── OWASP Dependency Check ───────────────────────────────────────────────────
install_owasp_dc() {
  local version="${1:-10.0.2}"
  local url="https://github.com/jeremylong/DependencyCheck/releases/download/v${version}/dependency-check-${version}-release.zip"

  echo "Installing OWASP Dependency Check ${version}..."
  dnf install -y unzip 2>/dev/null || true
  cd /opt
  curl -fsSL "$url" -o dependency-check.zip
  unzip -qo dependency-check.zip && rm -f dependency-check.zip
  ln -sfn /opt/dependency-check /opt/owasp-dc
  chmod +x /opt/dependency-check/bin/dependency-check.sh

  echo 'export PATH=$PATH:/opt/owasp-dc/bin' > /etc/profile.d/owasp.sh
  chmod +x /etc/profile.d/owasp.sh
  echo "OWASP DC ${version} installed at /opt/owasp-dc"
}

# ─── Entry Point ─────────────────────────────────────────────────────────────
case "${1:-all}" in
  maven)   install_maven "${2:-}" ;;
  trivy)   install_trivy "${2:-}" ;;
  owasp)   install_owasp_dc "${2:-}" ;;
  all)
    install_maven
    install_trivy
    install_owasp_dc
    ;;
  *)
    echo "Usage: $0 [all|maven|trivy|owasp] [version]"
    exit 1
    ;;
esac

echo "Done."
