#!/usr/bin/env bash
set -Eeuo pipefail

GRADLE_VERSION="9.4.1"
GRADLE_ZIP="gradle-${GRADLE_VERSION}-bin.zip"
GRADLE_URL="https://services.gradle.org/distributions/${GRADLE_ZIP}"
INSTALL_BASE="/opt/gradle"
INSTALL_DIR="${INSTALL_BASE}/gradle-${GRADLE_VERSION}"
LINK_PATH="/usr/local/bin/gradle"
PROFILE_FILE="/etc/profile.d/gradle.sh"
TMP_DIR="/tmp/gradle-install.$$"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "==> Installing prerequisites"
dnf install -y java-17-amazon-corretto-devel wget unzip

echo "==> Verifying Java"
java -version

echo "==> Preparing directories"
mkdir -p "${INSTALL_BASE}" "${TMP_DIR}"

if [[ -x "${INSTALL_DIR}/bin/gradle" ]]; then
  echo "==> Gradle ${GRADLE_VERSION} already installed at ${INSTALL_DIR}"
else
  echo "==> Downloading Gradle ${GRADLE_VERSION}"
  cd "${TMP_DIR}"
  wget -O "${GRADLE_ZIP}" "${GRADLE_URL}"

  echo "==> Extracting Gradle"
  unzip -q "${GRADLE_ZIP}"

  echo "==> Installing to ${INSTALL_BASE}"
  rm -rf "${INSTALL_DIR}"
  mv "gradle-${GRADLE_VERSION}" "${INSTALL_DIR}"
fi

echo "==> Creating symlink ${LINK_PATH}"
ln -sfn "${INSTALL_DIR}/bin/gradle" "${LINK_PATH}"

echo "==> Writing profile file ${PROFILE_FILE}"
cat > "${PROFILE_FILE}" <<EOF
export GRADLE_HOME="${INSTALL_DIR}"
export PATH="\$GRADLE_HOME/bin:\$PATH"
EOF
chmod 644 "${PROFILE_FILE}"

echo "==> Reloading shell profile for current session"
export GRADLE_HOME="${INSTALL_DIR}"
export PATH="${GRADLE_HOME}/bin:${PATH}"

echo "==> Verifying Gradle installation"
gradle --version

echo "==> Done"
echo "Gradle installed at: ${INSTALL_DIR}"
echo "Command available at: ${LINK_PATH}"