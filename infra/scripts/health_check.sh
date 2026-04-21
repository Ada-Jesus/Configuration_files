#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  health_check.sh  –  Poll /health via the ALB test listener (8080)
#
#  Validates the new slot BEFORE switching any live traffic.
#
#  Required env vars:
#    ALB_DNS_NAME
#
#  Optional env vars:
#    HEALTH_RETRIES  (default 20)
#    HEALTH_DELAY    (default 10 seconds)
#    HEALTH_PATH     (default /health)
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

RETRIES="${HEALTH_RETRIES:-20}"
DELAY="${HEALTH_DELAY:-10}"
PATH_TO_CHECK="${HEALTH_PATH:-/health}"
URL="http://${ALB_DNS_NAME}:8080${PATH_TO_CHECK}"

echo "==> Health-checking new slot via test listener"
echo "    URL:     ${URL}"
echo "    Retries: ${RETRIES}  Delay: ${DELAY}s"

for i in $(seq 1 "${RETRIES}"); do
  HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 5 \
    --connect-timeout 3 \
    "${URL}" || echo "000")

  if [ "${HTTP_CODE}" = "200" ]; then
    echo "==> Health check passed on attempt ${i}/${RETRIES} (HTTP ${HTTP_CODE})"
    exit 0
  fi

  echo "    Attempt ${i}/${RETRIES}: HTTP ${HTTP_CODE} – retrying in ${DELAY}s..."
  sleep "${DELAY}"
done

echo "ERROR: Health check failed after ${RETRIES} attempts"
exit 1
