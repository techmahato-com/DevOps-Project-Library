#!/bin/bash
# =============================================================================
# Jenkins Controller Bootstrap Script
# Target OS : Amazon Linux 2023 (AL2023)
# Logs      : /var/log/jenkins-bootstrap.log
# Compatible: EC2 user_data AND SSM RunShellScript
# =============================================================================
set -eux

LOG=/var/log/jenkins-bootstrap.log
touch "$LOG"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

log "Starting Jenkins bootstrap"

# ─── System Update ────────────────────────────────────────────────────────────
dnf update -y 2>&1 | tee -a "$LOG"

# ─── Java 17 ─────────────────────────────────────────────────────────────────
dnf install -y java-17-amazon-corretto-headless 2>&1 | tee -a "$LOG"
java -version 2>&1 | tee -a "$LOG"

# ─── Git ─────────────────────────────────────────────────────────────────────
dnf install -y git 2>&1 | tee -a "$LOG"

# ─── Docker ──────────────────────────────────────────────────────────────────
dnf install -y docker 2>&1 | tee -a "$LOG"
systemctl enable docker
systemctl start docker

# ─── Maven ───────────────────────────────────────────────────────────────────
MAVEN_VERSION="3.9.6"
if [ ! -d "/opt/apache-maven-${MAVEN_VERSION}" ]; then
  cd /opt
  curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    -o maven.tar.gz
  tar -xzf maven.tar.gz && rm -f maven.tar.gz
fi
ln -sfn "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven
export M2_HOME=/opt/maven
export PATH=$PATH:$M2_HOME/bin
cat > /etc/profile.d/maven.sh << 'PROFILE'
export M2_HOME=/opt/maven
export PATH=$PATH:$M2_HOME/bin
PROFILE
/opt/maven/bin/mvn -version 2>&1 | tee -a "$LOG"
log "Maven installed"

# ─── Trivy ───────────────────────────────────────────────────────────────────
TRIVY_VERSION="0.69.3"
if ! command -v trivy &>/dev/null; then
  rpm -ivh "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.rpm" \
    2>&1 | tee -a "$LOG" || log "WARNING: Trivy install failed — install manually"
fi

# ─── OWASP Dependency Check ───────────────────────────────────────────────────
OWASP_VERSION="10.0.2"
dnf install -y unzip 2>&1 | tee -a "$LOG"
if [ ! -f "/opt/dependency-check/bin/dependency-check.sh" ]; then
  cd /opt
  curl -fsSL "https://github.com/jeremylong/DependencyCheck/releases/download/v${OWASP_VERSION}/dependency-check-${OWASP_VERSION}-release.zip" \
    -o dependency-check.zip 2>&1 | tee -a "$LOG" && \
  unzip -q dependency-check.zip && rm -f dependency-check.zip && \
  ln -sfn /opt/dependency-check /opt/owasp-dc && \
  chmod +x /opt/dependency-check/bin/dependency-check.sh && \
  echo 'export PATH=$PATH:/opt/owasp-dc/bin' > /etc/profile.d/owasp.sh || \
  log "WARNING: OWASP DC install failed — install manually"
fi

# ─── Jenkins LTS ─────────────────────────────────────────────────────────────
if ! command -v jenkins &>/dev/null; then
  curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.repo \
    -o /etc/yum.repos.d/jenkins.repo
  rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
  dnf install -y jenkins 2>&1 | tee -a "$LOG"
fi

# ─── Enable & Start Services ──────────────────────────────────────────────────
systemctl enable jenkins
systemctl start jenkins
usermod -aG docker jenkins
systemctl restart jenkins

log "Bootstrap complete"
log "Jenkins status: $(systemctl is-active jenkins)"

# Print initial admin password when ready (wait up to 60s)
for i in $(seq 1 12); do
  if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    log "Initial admin password: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
    break
  fi
  sleep 5
done
