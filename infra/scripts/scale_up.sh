#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  scale_up.sh  –  Update deploy slot with new task def & scale up
#
#  Required env vars:
#    ECS_CLUSTER
#    DEPLOY_SERVICE
#    TASK_DEF_ARN
#    DESIRED_COUNT
#    AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Scaling up: ${DEPLOY_SERVICE}"

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${DEPLOY_SERVICE}" \
  --task-definition "${TASK_DEF_ARN}" \
  --desired-count "${DESIRED_COUNT}" \
  --region "${AWS_REGION}"

aws ecs wait services-stable \
  --cluster "${ECS_CLUSTER}" \
  --services "${DEPLOY_SERVICE}"

echo "==> Deploy slot stable"
