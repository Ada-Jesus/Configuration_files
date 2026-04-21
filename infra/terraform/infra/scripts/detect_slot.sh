#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  detect_slot.sh  –  Determine which ECS slot (blue/green) is live
#
#  Required env vars:
#    ALB_LISTENER_ARN, BLUE_TG_ARN, GREEN_TG_ARN
#    BLUE_SERVICE, GREEN_SERVICE, AWS_REGION
#    GITHUB_OUTPUT
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Detecting currently LIVE slot..."

# ── Validate required env vars ─────────────────────────────────────
required_vars=(
  ALB_LISTENER_ARN
  BLUE_TG_ARN
  GREEN_TG_ARN
  BLUE_SERVICE
  GREEN_SERVICE
  AWS_REGION
  GITHUB_OUTPUT
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: Missing required env var: $var"
    exit 1
  fi
done

# ── Get current live target group from ALB ─────────────────────────
LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "${ALB_LISTENER_ARN}" \
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
  --output text \
  --region "${AWS_REGION}")

echo "    Current live target group: ${LIVE_TG}"

# ── Determine slots ────────────────────────────────────────────────
if [ "${LIVE_TG}" = "${BLUE_TG_ARN}" ]; then
  LIVE_SERVICE="${BLUE_SERVICE}"
  LIVE_TG_ARN="${BLUE_TG_ARN}"
  DEPLOY_SERVICE="${GREEN_SERVICE}"
  DEPLOY_TG_ARN="${GREEN_TG_ARN}"
  echo "    Live slot: BLUE  → deploying to: GREEN"
elif [ "${LIVE_TG}" = "${GREEN_TG_ARN}" ]; then
  LIVE_SERVICE="${GREEN_SERVICE}"
  LIVE_TG_ARN="${GREEN_TG_ARN}"
  DEPLOY_SERVICE="${BLUE_SERVICE}"
  DEPLOY_TG_ARN="${BLUE_TG_ARN}"
  echo "    Live slot: GREEN → deploying to: BLUE"
else
  echo "ERROR: Could not determine live slot (unexpected target group)"
  exit 1
fi

# ── Export outputs for GitHub Actions ──────────────────────────────
{
  echo "live_service=${LIVE_SERVICE}"
  echo "live_tg=${LIVE_TG_ARN}"
  echo "deploy_service=${DEPLOY_SERVICE}"
  echo "deploy_tg=${DEPLOY_TG_ARN}"
} >> "${GITHUB_OUTPUT}"

echo ""
echo "==> Slot detection complete"
echo "    LIVE:   ${LIVE_SERVICE}"
echo "    DEPLOY: ${DEPLOY_SERVICE}"
