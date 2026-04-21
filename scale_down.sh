#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  scale_down.sh  –  Scale old (previously live) slot to zero
#
#  Called after traffic has switched and post-switch validation
#  has passed. Keeps the service registered so the next deployment
#  can scale it back up.
#
#  Required env vars:
#    ECS_CLUSTER, LIVE_SERVICE, AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Scaling down old slot: ${LIVE_SERVICE}"

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${LIVE_SERVICE}" \
  --desired-count 0 \
  --region "${AWS_REGION}" \
  --output json | jq '.service | {status, desiredCount, runningCount}'

echo "==> ${LIVE_SERVICE} scaled to 0 – ready for next deployment cycle"
