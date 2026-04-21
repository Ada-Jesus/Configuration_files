#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  detect_slot.sh  –  Determine which ECS slot (blue/green) is live
#
#  Reads the current ALB listener's default target group and sets
#  GITHUB_OUTPUT vars for downstream steps.
#
#  Required env vars:
#    ALB_LISTENER_ARN, BLUE_TG_ARN, GREEN_TG_ARN
#    BLUE_SERVICE, GREEN_SERVICE, AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Querying ALB listener: ${ALB_LISTENER_ARN}"

LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "${ALB_LISTENER_ARN}" \
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
  --output text \
  --region "${AWS_REGION}")

echo "    Live target group: ${LIVE_TG}"

if [ "${LIVE_TG}" = "${BLUE_TG_ARN}" ]; then
  LIVE_SERVICE="${BLUE_SERVICE}"
  LIVE_TG_ARN="${BLUE_TG_ARN}"
  DEPLOY_SERVICE="${GREEN_SERVICE}"
  DEPLOY_TG_ARN="${GREEN_TG_ARN}"
  echo "    Live slot: BLUE  → deploying to: GREEN"
else
  LIVE_SERVICE="${GREEN_SERVICE}"
  LIVE_TG_ARN="${GREEN_TG_ARN}"
  DEPLOY_SERVICE="${BLUE_SERVICE}"
  DEPLOY_TG_ARN="${BLUE_TG_ARN}"
  echo "    Live slot: GREEN → deploying to: BLUE"
fi

# Write to GitHub Actions output
{
  echo "live_service=${LIVE_SERVICE}"
  echo "live_tg=${LIVE_TG_ARN}"
  echo "deploy_service=${DEPLOY_SERVICE}"
  echo "deploy_tg=${DEPLOY_TG_ARN}"
} >> "${GITHUB_OUTPUT}"

echo "==> Slot detection complete"
