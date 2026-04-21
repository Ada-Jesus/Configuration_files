#!/usr/bin/env bash
set -euo pipefail

DURATION="${BURNIN_DURATION:-300}"
THRESHOLD="${BURNIN_THRESHOLD:-10}"
INTERVAL="${BURNIN_INTERVAL:-30}"
END_TIME=$(( $(date +%s) + DURATION ))

while [ "$(date +%s)" -lt "${END_TIME}" ]; do
  WINDOW_START=$(date -u -d "2 minutes ago" +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
                 date -u -v-2M +'%Y-%m-%dT%H:%M:%SZ')

  WINDOW_END=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

  ERRORS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name HTTPCode_Target_5XX_Count \
    --dimensions "Name=LoadBalancer,Value=${ALB_ARN_SUFFIX}" \
    --start-time "${WINDOW_START}" \
    --end-time "${WINDOW_END}" \
    --period 120 \
    --statistics Sum \
    --query 'Datapoints[0].Sum' \
    --output text \
    --region "${AWS_REGION}" 2>/dev/null || echo "0")

  ERRORS="${ERRORS:-0}"
  ERRORS_INT=$(printf "%.0f" "${ERRORS}" 2>/dev/null || echo "${ERRORS%%.*}")

  if [ "${ERRORS_INT}" -gt "${THRESHOLD}" ]; then
    echo "ERROR: High 5xx error rate (${ERRORS_INT})"
    exit 1
  fi

  sleep "${INTERVAL}"
done

echo "==> Burn-in passed"