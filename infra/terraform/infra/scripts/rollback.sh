#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  rollback.sh  –  Emergency rollback to previous slot
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Validate env vars ──────────────────────────────────────────────
required_vars=(
  ECS_CLUSTER
  ALB_LISTENER_ARN
  AWS_REGION
  BLUE_SERVICE
  GREEN_SERVICE
  BLUE_TG_ARN
  GREEN_TG_ARN
  DESIRED_COUNT
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: Missing required env var: $var"
    exit 1
  fi
done

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      EMERGENCY ROLLBACK INITIATED        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Detect live slot ───────────────────────────────────────────
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
  echo "    Live: BLUE → rollback to GREEN"
elif [ "${LIVE_TG}" = "${GREEN_TG_ARN}" ]; then
  LIVE_SERVICE="${GREEN_SERVICE}"
  PREV_SERVICE="${BLUE_SERVICE}"
  PREV_TG_ARN="${BLUE_TG_ARN}"
  echo "    Live: GREEN → rollback to BLUE"
else
  echo "ERROR: Unknown target group on listener"
  exit 1
fi

# ── 2. Scale up previous slot ─────────────────────────────────────
echo ""
echo "--> Scaling up: ${PREV_SERVICE}"

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${PREV_SERVICE}" \
  --desired-count "${DESIRED_COUNT}" \
  --region "${AWS_REGION}" \
  --output json | jq '.service | {status, desiredCount, runningCount, pendingCount}'

echo "--> Waiting for service stability..."

aws ecs wait services-stable \
  --cluster "${ECS_CLUSTER}" \
  --services "${PREV_SERVICE}" \
  --region "${AWS_REGION}"

echo "    ${PREV_SERVICE} is stable"

# ── 3. Health check ───────────────────────────────────────────────
echo ""
echo "--> Health check before switch..."

HEALTHY=false

for i in 1 2 3 4 5; do
  CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 5 \
    "http://${ALB_DNS_NAME:-localhost}:8080/health" || echo "000")

  echo "    Attempt ${i}/5 → HTTP ${CODE}"

  if [ "${CODE}" = "200" ]; then
    HEALTHY=true
    break
  fi

  sleep 5
done

if [ "${HEALTHY}" != "true" ]; then
  echo "WARNING: Health check failed — continuing rollback anyway"
fi

# ── 4. Switch traffic ─────────────────────────────────────────────
echo ""
echo "--> Switching traffic to ${PREV_SERVICE}"

aws elbv2 modify-listener \
  --listener-arn "${ALB_LISTENER_ARN}" \
  --default-actions "Type=forward,TargetGroupArn=${PREV_TG_ARN}" \
  --region "${AWS_REGION}" \
  --output json | jq '.Listeners[0] | {ListenerArn, Port}'

# ── 5. Scale down failed slot ─────────────────────────────────────
echo ""
echo "--> Scaling down failed slot: ${LIVE_SERVICE}"

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
echo "  LIVE:   ${PREV_SERVICE}"
echo "  FAILED: ${LIVE_SERVICE}"
echo ""
echo "  Verify: http://${ALB_DNS_NAME:-<ALB_DNS_NAME>}/health"
echo ""
