#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  validate_and_rollback.sh  –  Post-switch health check + auto-rollback
#
#  Polls /health on the live ALB endpoint after traffic switch.
#  If any check fails, immediately reverts the listener to the
#  previous (live) target group — rollback within ~60 seconds.
#
#  Required env vars:
#    ALB_DNS_NAME, ALB_LISTENER_ARN
#    LIVE_TG_ARN    (previous slot – rollback target)
#    LIVE_SERVICE   (previous slot service name)
#    DEPLOY_SERVICE (new slot service name)
#    AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

CHECKS="${VALIDATION_CHECKS:-5}"
DELAY="${VALIDATION_DELAY:-5}"
URL="http://${ALB_DNS_NAME}/health"

echo "==> Post-switch validation"
echo "    URL:    ${URL}"
echo "    Checks: ${CHECKS}  Delay: ${DELAY}s"
echo ""

# Give the ALB a moment to propagate the listener change
sleep 10

rollback() {
  echo ""
  echo "!!! ROLLBACK INITIATED !!!"
  echo "    Reverting listener to: ${LIVE_TG_ARN}"

  aws elbv2 modify-listener \
    --listener-arn "${ALB_LISTENER_ARN}" \
    --default-actions "Type=forward,TargetGroupArn=${LIVE_TG_ARN}" \
    --region "${AWS_REGION}" > /dev/null

  echo "    Listener reverted – ${LIVE_SERVICE} is LIVE again"
  echo "    Deployment of ${DEPLOY_SERVICE} has been rolled back"
  exit 1
}

# Trap any unexpected errors and roll back
trap rollback ERR

for i in $(seq 1 "${CHECKS}"); do
  HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    --connect-timeout 5 \
    "${URL}" || echo "000")

  echo "  Check ${i}/${CHECKS}: HTTP ${HTTP_CODE}"

  if [ "${HTTP_CODE}" != "200" ]; then
    echo "  FAIL – expected 200, got ${HTTP_CODE}"
    rollback
  fi

  [ "${i}" -lt "${CHECKS}" ] && sleep "${DELAY}"
done

# All good – remove the error trap
trap - ERR

echo ""
echo "==> Post-switch validation passed – deployment successful"
