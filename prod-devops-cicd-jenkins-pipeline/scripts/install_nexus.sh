#!/bin/bash
set -e

NEXUS_VERSION="3.78.0-14"
NEXUS_USER="nexus"
NEXUS_HOME="/opt/nexus"
NEXUS_DATA="/opt/sonatype-work"
TMP_DIR="/tmp/nexus-install"
NEXUS_TAR="nexus-unix-x86-64-${NEXUS_VERSION}.tar.gz"
NEXUS_URL="https://download.sonatype.com/nexus/3/${NEXUS_TAR}"

echo "==== Updating packages ===="
dnf update -y
dnf install -y java-17-amazon-corretto-devel wget tar

echo "==== Creating nexus user if not exists ===="
id -u ${NEXUS_USER} >/dev/null 2>&1 || useradd -r -m -U -d ${NEXUS_HOME} -s /bin/bash ${NEXUS_USER}

echo "==== Cleaning old install ===="
systemctl stop nexus 2>/dev/null || true
systemctl disable nexus 2>/dev/null || true
pkill -f nexus 2>/dev/null || true
rm -f /etc/systemd/system/nexus.service
rm -rf ${NEXUS_HOME}
rm -rf ${NEXUS_DATA}
rm -rf ${TMP_DIR}

echo "==== Preparing directories ===="
mkdir -p ${TMP_DIR}
mkdir -p ${NEXUS_DATA}

echo "==== Downloading Nexus ===="
cd ${TMP_DIR}
wget ${NEXUS_URL} -O nexus.tar.gz

echo "==== Extracting Nexus ===="
tar -xzf nexus.tar.gz

EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "nexus-*" | head -1 | sed 's|^\./||')

if [ -z "${EXTRACTED_DIR}" ]; then
  echo "Nexus archive extraction failed"
  exit 1
fi

echo "==== Installing Nexus ===="
mv "${EXTRACTED_DIR}" ${NEXUS_HOME}

echo "==== Setting ownership ===="
chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_HOME}
chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_DATA}

echo "==== Configuring nexus user ===="
cat > ${NEXUS_HOME}/bin/nexus.rc <<EOF
run_as_user="${NEXUS_USER}"
EOF

echo "==== Configuring nexus data path ===="
if ! grep -q "karaf.data=${NEXUS_DATA}/nexus3" ${NEXUS_HOME}/bin/nexus.vmoptions; then
  echo "-Dkaraf.data=${NEXUS_DATA}/nexus3" >> ${NEXUS_HOME}/bin/nexus.vmoptions
fi

echo "==== Creating systemd service ===="
cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=${NEXUS_USER}
Group=${NEXUS_USER}
ExecStart=${NEXUS_HOME}/bin/nexus start
ExecStop=${NEXUS_HOME}/bin/nexus stop
Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOF

echo "==== Reloading systemd ===="
systemctl daemon-reload
systemctl enable nexus

echo "==== Starting Nexus ===="
systemctl start nexus

echo "==== Waiting for Nexus to initialize ===="
sleep 90

echo "==== Status ===="
systemctl status nexus --no-pager || true
ss -tulpn | grep 8081 || true

echo "==== Admin password location ===="
find /opt -name admin.password 2>/dev/null || true