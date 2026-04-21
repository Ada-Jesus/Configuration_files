#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  smoke_test.sh  –  Run smoke tests against the new slot (port 8080)
#
#  Required env vars:
#    ALB_DNS_NAME
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

BASE="http://${ALB_DNS_NAME}:8080"
FAIL=0

# Format: "METHOD ENDPOINT EXPECTED_CODE"
ENDPOINTS=(
  "GET /health 200"
  "GET /health/ready 200"
  "GET /health/live 200"
)

echo "==> Running smoke tests against ${BASE}"
echo "    Endpoints: ${#ENDPOINTS[@]}"
echo ""

for entry in "${ENDPOINTS[@]}"; do
  read -r METHOD ENDPOINT EXPECTED <<< "${entry}"
  URL="${BASE}${ENDPOINT}"

  HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    --connect-timeout 5 \
    -X "${METHOD}" \
    "${URL}" || echo "000")

  if [ "${HTTP_CODE}" = "${EXPECTED}" ]; then
    echo "  PASS  ${METHOD} ${ENDPOINT} → ${HTTP_CODE}"
  else
    echo "  FAIL  ${METHOD} ${ENDPOINT} → ${HTTP_CODE} (expected ${EXPECTED})"
    FAIL=1
  fi
done

echo ""
if [ "${FAIL}" -ne 0 ]; then
  echo "ERROR: One or more smoke tests failed"
  exit 1
fi

echo "==> All smoke tests passed"
