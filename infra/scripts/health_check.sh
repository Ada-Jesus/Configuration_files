#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  health_check.sh  –  Poll /health via ALB test listener (8080)
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Validate required env vars ─────────────────────────────────────
if [ -z "${ALB_DNS_NAME:-}" ]; then
  echo "ERROR: ALB_DNS_NAME is required"
  exit 1
fi

RETRIES="${HEALTH_RETRIES:-20}"
DELAY="${HEALTH_DELAY:-10}"
PATH_TO_CHECK="${HEALTH_PATH:-/health}"
URL="http://${ALB_DNS_NAME}:8080${PATH_TO_CHECK}"

echo "==> Health-checking NEW slot (pre-traffic)"
echo "    URL:     ${URL}"
echo "    Retries: ${RETRIES}"
echo "    Delay:   ${DELAY}s"
echo ""

for i in $(seq 1 "${RETRIES}"); do
  HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 5 \
    --connect-timeout 3 \
    "${URL}" || echo "000")

  if [ "${HTTP_CODE}" = "200" ]; then
    echo "==> SUCCESS: Healthy on attempt ${i}/${RETRIES}"
    exit 0
  fi

  echo "  Attempt ${i}/${RETRIES}: HTTP ${HTTP_CODE} → retrying..."
  sleep "${DELAY}"
done

echo ""
echo "ERROR: Health check FAILED after ${RETRIES} attempts"
echo "       Endpoint: ${URL}"
exit 1
