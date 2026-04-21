#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  monitor_burnin.sh  –  5-minute error rate burn-in after deploy
#
#  Polls CloudWatch every 30 seconds for 5xx count.
#  Exits non-zero if error rate exceeds threshold (triggering
#  GitHub Actions to flag the deploy as failed).
#
#  Required env vars:
#    AWS_REGION, ALB_ARN_SUFFIX
#
#  Optional env vars:
#    BURNIN_DURATION   seconds to monitor (default 300 = 5 min)
#    BURNIN_THRESHOLD  max 5xx errors per 2-min window (default 10)
#    BURNIN_INTERVAL   poll interval in seconds (default 30)
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

DURATION="${BURNIN_DURATION:-300}"
THRESHOLD="${BURNIN_THRESHOLD:-10}"
INTERVAL="${BURNIN_INTERVAL:-30}"
END_TIME=$(( $(date +%s) + DURATION ))

echo "==> Post-deploy burn-in monitor"
echo "    Duration:  ${DURATION}s"
echo "    Threshold: ${THRESHOLD} 5xx errors per 2-minute window"
echo "    Interval:  ${INTERVAL}s polling"
echo ""

CHECKS=0
FAILS=0

while [ "$(date +%s)" -lt "${END_TIME}" ]; do
  WINDOW_START=$(date -u -d "2 minutes ago" +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
                 date -u -v-2M +'%Y-%m-%dT%H:%M:%SZ')   # macOS fallback
  WINDOW_END=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

  ERRORS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name HTTPCode_Target_5XX_Count \
    --dimensions "Name=LoadBalancer,Value=${ALB_ARN_SUFFIX}" \
    --start-time "${WINDOW_START}" \
    --end-time   "${WINDOW_END}" \
    --period 120 \
    --statistics Sum \
    --query 'Datapoints[0].Sum' \
    --output text \
    --region "${AWS_REGION}" 2>/dev/null || echo "None")

  # Treat None/empty as 0
  ERRORS="${ERRORS:-0}"
  [ "${ERRORS}" = "None" ] && ERRORS=0

  # Strip decimal (bc not always available)
  ERRORS_INT=$(printf "%.0f" "${ERRORS}" 2>/dev/null || echo "${ERRORS%%.*}")

  CHECKS=$(( CHECKS + 1 ))
  REMAINING=$(( END_TIME - $(date +%s) ))

  echo "  [$(date +'%H:%M:%S')] 5xx in last 2min: ${ERRORS_INT}  (${REMAINING}s remaining)"

  if [ "${ERRORS_INT}" -gt "${THRESHOLD}" ]; then
    FAILS=$(( FAILS + 1 ))
    echo "  WARNING: Error count ${ERRORS_INT} exceeds threshold ${THRESHOLD}"

    # Allow one transient spike; two consecutive failures = abort
    if [ "${FAILS}" -ge 2 ]; then
      echo ""
      echo "ERROR: Persistent high error rate detected after ${CHECKS} checks"
      echo "       Consider running scripts/rollback.sh"
      exit 1
    fi
  else
    FAILS=0
  fi

  REMAINING=$(( END_TIME - $(date +%s) ))
  [ "${REMAINING}" -gt 0 ] && sleep "${INTERVAL}"
done

echo ""
echo "==> Burn-in complete after ${CHECKS} checks – deployment healthy"
