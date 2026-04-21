#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  rollback.sh  –  Emergency manual rollback to the previous slot
#
#  Detects which slot is currently live, scales up the other slot
#  with its existing task definition, then atomically switches
#  the ALB listener back. Total time: ~60 seconds.
#
#  Required env vars:
#    ECS_CLUSTER, ALB_LISTENER_ARN, AWS_REGION
#    BLUE_SERVICE, GREEN_SERVICE
#    BLUE_TG_ARN,  GREEN_TG_ARN
#    DESIRED_COUNT
#
#  Usage:
#    export AWS_REGION=us-east-1
#    export ECS_CLUSTER=aspnet-api-production
#    export ALB_LISTENER_ARN=arn:aws:elasticloadbalancing:...
#    export BLUE_SERVICE=aspnet-api-production-blue
#    export GREEN_SERVICE=aspnet-api-production-green
#    export BLUE_TG_ARN=arn:aws:elasticloadbalancing:...
#    export GREEN_TG_ARN=arn:aws:elasticloadbalancing:...
#    export DESIRED_COUNT=2
#    bash rollback.sh
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      EMERGENCY ROLLBACK INITIATED        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Detect which slot is currently live ────────────────────────
echo "--> Detecting live slot..."

LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "${ALB_LISTENER_ARN}" \
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
  --output text \
  --region "${AWS_REGION}")

if [ "${LIVE_TG}" = "${BLUE_TG_ARN}" ]; then
  LIVE_SERVICE="${BLUE_SERVICE}"
  PREV_SERVICE="${GREEN_SERVICE}"
  PREV_TG_ARN="${GREEN_TG_ARN}"
  echo "    Live slot: BLUE  → rolling back to: GREEN"
else
  LIVE_SERVICE="${GREEN_SERVICE}"
  PREV_SERVICE="${BLUE_SERVICE}"
  PREV_TG_ARN="${BLUE_TG_ARN}"
  echo "    Live slot: GREEN → rolling back to: BLUE"
fi

# ── 2. Scale up the previous slot ────────────────────────────────
echo ""
echo "--> Scaling up previous slot: ${PREV_SERVICE} (count: ${DESIRED_COUNT})"

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${PREV_SERVICE}" \
  --desired-count "${DESIRED_COUNT}" \
  --region "${AWS_REGION}" \
  --output json | jq '.service | {status, desiredCount, runningCount, pendingCount}'

echo "--> Waiting for ${PREV_SERVICE} to stabilise..."

aws ecs wait services-stable \
  --cluster "${ECS_CLUSTER}" \
  --services "${PREV_SERVICE}" \
  --region "${AWS_REGION}"

echo "    ${PREV_SERVICE} is stable"

# ── 3. Quick health check before switching ────────────────────────
echo ""
echo "--> Health-checking ${PREV_SERVICE} via test listener..."

HEALTHY=false
for i in 1 2 3 4 5; do
  CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 5 \
    "http://${ALB_DNS_NAME:-localhost}:8080/health" || echo "000")
  echo "    Attempt ${i}/5: HTTP ${CODE}"
  if [ "${CODE}" = "200" ]; then
    HEALTHY=true
    break
  fi
  sleep 5
done

if [ "${HEALTHY}" != "true" ]; then
  echo "WARNING: Health checks did not pass on test listener."
  echo "         Proceeding with rollback anyway (previous slot was last known-good)."
fi

# ── 4. Switch live traffic back ───────────────────────────────────
echo ""
echo "--> Switching ALB listener to ${PREV_SERVICE}..."

aws elbv2 modify-listener \
  --listener-arn "${ALB_LISTENER_ARN}" \
  --default-actions "Type=forward,TargetGroupArn=${PREV_TG_ARN}" \
  --region "${AWS_REGION}" \
  --output json | jq '.Listeners[0] | {ListenerArn, Protocol, Port}'

# ── 5. Scale down the failed slot ────────────────────────────────
echo ""
echo "--> Scaling down failed slot: ${LIVE_SERVICE}..."

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${LIVE_SERVICE}" \
  --desired-count 0 \
  --region "${AWS_REGION}" \
  --output json | jq '.service | {status, desiredCount}'

# ── 6. Summary ────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║          ROLLBACK COMPLETE               ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Previous (now live):  ${PREV_SERVICE}"
echo "  Failed (scaled down): ${LIVE_SERVICE}"
echo ""
echo "  Verify at: http://${ALB_DNS_NAME:-<ALB_DNS_NAME>}/health"
echo ""
