#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  switch_traffic.sh  –  Atomically move live traffic to new slot
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Switching ALB traffic → ${DEPLOY_TG_ARN}"

aws elbv2 modify-listener \
  --listener-arn "${ALB_LISTENER_ARN}" \
  --default-actions "Type=forward,TargetGroupArn=${DEPLOY_TG_ARN}" \
  --region "${AWS_REGION}"

echo "==> Traffic switched"
