#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  scale_down.sh  –  Scale old (previously live) slot to zero
#
#  Called after:
#    - traffic switch
#    - validation
#    - burn-in monitoring
#
#  Required env vars:
#    ECS_CLUSTER
#    LIVE_SERVICE
#    AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${LIVE_SERVICE}" \
  --desired-count 0 \
  --region "${AWS_REGION}"
