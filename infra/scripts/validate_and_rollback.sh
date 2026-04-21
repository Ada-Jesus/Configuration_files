#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  validate_and_rollback.sh  –  Post-switch validation + auto-rollback
#
#  Required env vars:
#    ALB_DNS_NAME, ALB_LISTENER_ARN
#    LIVE_TG_ARN
#    LIVE_SERVICE
#    DEPLOY_SERVICE
#    ECS_CLUSTER
#    DESIRED_COUNT
#    AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

URL="http://${ALB_DNS_NAME}/health"

rollback() {
  aws elbv2 modify-listener \
    --listener-arn "${ALB_LISTENER_ARN}" \
    --default-actions "Type=forward,TargetGroupArn=${LIVE_TG_ARN}" \
    --region "${AWS_REGION}"
  exit 1
}

trap rollback ERR

for i in $(seq 1 5); do
  CODE=$(curl -sf -o /dev/null -w "%{http_code}" "${URL}" || echo "000")

  if [ "${CODE}" != "200" ]; then
    rollback
  fi

  sleep 5
done

trap - ERR
echo "==> Validation passed"