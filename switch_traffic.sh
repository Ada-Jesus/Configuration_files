#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  switch_traffic.sh  –  Atomically move live traffic to new slot
#
#  A single modify-listener call is atomic on the ALB side – no
#  requests are dropped during the switch.
#
#  Required env vars:
#    ALB_LISTENER_ARN, DEPLOY_TG_ARN, DEPLOY_SERVICE, AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Switching ALB listener to new slot"
echo "    Listener:         ${ALB_LISTENER_ARN}"
echo "    Target group:     ${DEPLOY_TG_ARN}"
echo "    Incoming service: ${DEPLOY_SERVICE}"

aws elbv2 modify-listener \
  --listener-arn "${ALB_LISTENER_ARN}" \
  --default-actions "Type=forward,TargetGroupArn=${DEPLOY_TG_ARN}" \
  --region "${AWS_REGION}" \
  --output json | jq '.Listeners[0] | {ListenerArn, Protocol, Port}'

echo "==> Traffic switch complete – ${DEPLOY_SERVICE} is now LIVE"
