#!/bin/bash
# =============================================================================
# Health Check Script
# Checks Jenkins and SonarQube reachability from within the VPC.
# Usage: ./health_check.sh <jenkins-private-ip> <sonarqube-private-ip>
# =============================================================================
set -euo pipefail

JENKINS_IP="${1:?Usage: $0 <jenkins-private-ip> <sonarqube-private-ip>}"
SONAR_IP="${2:?Usage: $0 <jenkins-private-ip> <sonarqube-private-ip>}"
JENKINS_PORT="${JENKINS_PORT:-8080}"
SONAR_PORT="${SONAR_PORT:-9000}"
TIMEOUT=5
EXIT_CODE=0

check() {
  local name="$1" url="$2"
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" || echo "000")

  if [[ "$http_code" =~ ^(200|403|302|301)$ ]]; then
    echo "[OK]   ${name} is reachable at ${url} (HTTP ${http_code})"
  else
    echo "[FAIL] ${name} is NOT reachable at ${url} (HTTP ${http_code})"
    EXIT_CODE=1
  fi
}

echo "=== Health Check: $(date) ==="
check "Jenkins"   "http://${JENKINS_IP}:${JENKINS_PORT}/login"
check "SonarQube" "http://${SONAR_IP}:${SONAR_PORT}"

exit "$EXIT_CODE"
