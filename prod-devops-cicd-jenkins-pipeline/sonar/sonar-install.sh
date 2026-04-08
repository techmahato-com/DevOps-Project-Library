#!/bin/bash
# =============================================================================
# SonarQube Bootstrap — Direct EC2 Install (no Docker)
# Target OS : Amazon Linux 2023 (AL2023)
# SonarQube : 10.4.1 LTS Community
# Java      : 17 (Corretto) — required, Java 21 not supported by SQ 10.x
# Logs      : /var/log/sonar-bootstrap.log
# =============================================================================
set -eux

LOG=/var/log/sonar-bootstrap.log
touch "$LOG"
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

SONAR_VERSION="10.4.1.88267"
SONAR_DIR="/opt/sonarqube"
SONAR_USER="sonarqube"
JAVA17="/usr/lib/jvm/java-17-amazon-corretto.x86_64"

log "Starting SonarQube direct install"

# ─── Java 17 ──────────────────────────────────────────────────────────────────
dnf install -y java-17-amazon-corretto-headless 2>&1 | tee -a "$LOG"
"$JAVA17/bin/java" -version 2>&1 | tee -a "$LOG"

# ─── Kernel params (required by embedded Elasticsearch) ───────────────────────
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
cat > /etc/sysctl.d/99-sonarqube.conf << 'EOF'
vm.max_map_count=524288
fs.file-max=131072
EOF

cat > /etc/security/limits.d/99-sonarqube.conf << 'EOF'
sonarqube   soft   nofile   65536
sonarqube   hard   nofile   65536
sonarqube   soft   nproc    4096
sonarqube   hard   nproc    4096
EOF

# ─── SonarQube user ───────────────────────────────────────────────────────────
id "$SONAR_USER" &>/dev/null || useradd -r -m -d "$SONAR_DIR" -s /sbin/nologin "$SONAR_USER"

# ─── Download & install SonarQube ─────────────────────────────────────────────
if [ ! -d "$SONAR_DIR/bin" ]; then
  log "Downloading SonarQube $SONAR_VERSION..."
  curl -fsSL \
    "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip" \
    -o /tmp/sonarqube.zip

  dnf install -y unzip 2>&1 | tee -a "$LOG"
  unzip -q /tmp/sonarqube.zip -d /tmp/sonarqube-extract
  mv /tmp/sonarqube-extract/sonarqube-${SONAR_VERSION} "$SONAR_DIR"
  rm -rf /tmp/sonarqube.zip /tmp/sonarqube-extract
fi

mkdir -p "$SONAR_DIR/conf"
chown -R "$SONAR_USER":"$SONAR_USER" "$SONAR_DIR"

# ─── sonar.properties ─────────────────────────────────────────────────────────
cat > "$SONAR_DIR/conf/sonar.properties" << 'EOF'
# Embedded H2 (dev only) — replace with RDS PostgreSQL for production:
# sonar.jdbc.url=jdbc:postgresql://<rds-endpoint>:5432/sonarqube
# sonar.jdbc.username=sonar
# sonar.jdbc.password=<password>

sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false
EOF

# ─── systemd service ──────────────────────────────────────────────────────────
cat > /etc/systemd/system/sonarqube.service << EOF
[Unit]
Description=SonarQube
After=network.target

[Service]
Type=simple
User=$SONAR_USER
Group=$SONAR_USER
Environment=JAVA_HOME=$JAVA17
WorkingDirectory=$SONAR_DIR
ExecStart=$JAVA17/bin/java \\
  -Xms512m -Xmx512m \\
  -XX:+HeapDumpOnOutOfMemoryError \\
  -Djava.net.preferIPv4Stack=true \\
  -jar $SONAR_DIR/lib/sonar-application-${SONAR_VERSION}.jar
Restart=on-failure
TimeoutStartSec=300
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# ─── Start service ────────────────────────────────────────────────────────────
systemctl daemon-reload
systemctl enable sonarqube
systemctl restart sonarqube

# ─── Wait for SonarQube to be ready (up to 3 min) ────────────────────────────
log "Waiting for SonarQube to start (up to 3 min)..."
for i in $(seq 1 36); do
  STATUS=$(curl -sf http://localhost:9000/api/system/status 2>/dev/null || echo "")
  if echo "$STATUS" | grep -q '"status":"UP"'; then
    log "SonarQube is UP"
    break
  fi
  sleep 5
done

log "SonarQube install complete"
log "Service: $(systemctl is-active sonarqube)"
log "Access:  http://$(hostname -I | awk '{print $1}'):9000"
log "Default credentials: admin / admin"
