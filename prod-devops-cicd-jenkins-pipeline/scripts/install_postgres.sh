#!/bin/bash
# =============================================================================
# PostgreSQL 15 Bootstrap — Direct EC2 Install
# Target OS : Amazon Linux 2023 (AL2023)
# Logs      : /var/log/postgres-bootstrap.log
# =============================================================================
set -eux

LOG=/var/log/postgres-bootstrap.log
touch "$LOG"
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

log "Starting PostgreSQL bootstrap"

# ─── Install PostgreSQL 15 ────────────────────────────────────────────────────
dnf install -y postgresql15 postgresql15-server 2>&1 | tee -a "$LOG"

# ─── Initialize DB (only if not already done) ─────────────────────────────────
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
  log "Initializing PostgreSQL data directory..."
  postgresql-setup --initdb 2>&1 | tee -a "$LOG"
fi

# ─── Configure listen address ─────────────────────────────────────────────────
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf

# Allow VPC CIDR connections (md5 auth)
grep -q "10.0.0.0/16" /var/lib/pgsql/data/pg_hba.conf || \
  echo "host  all  all  10.0.0.0/16  md5" >> /var/lib/pgsql/data/pg_hba.conf

# Change localhost ident → md5
sed -i 's/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            md5/' /var/lib/pgsql/data/pg_hba.conf

# ─── Enable & start ───────────────────────────────────────────────────────────
systemctl enable postgresql
systemctl restart postgresql

# ─── Create sonarqube DB + user ───────────────────────────────────────────────
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='sonar'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER sonar WITH PASSWORD 'sonar';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='sonarqube'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"

log "PostgreSQL bootstrap complete"
log "Service: $(systemctl is-active postgresql)"
log "DB: sonarqube | User: sonar | Password: sonar (change in production!)"
