#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  scale_up.sh  –  Update deploy slot with new task def & scale up
#
#  Required env vars:
#    ECS_CLUSTER, DEPLOY_SERVICE, TASK_DEF_ARN, DESIRED_COUNT, AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Updating service: ${DEPLOY_SERVICE}"
echo "    Task definition:  ${TASK_DEF_ARN}"
echo "    Desired count:    ${DESIRED_COUNT}"

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${DEPLOY_SERVICE}" \
  --task-definition "${TASK_DEF_ARN}" \
  --desired-count "${DESIRED_COUNT}" \
  --region "${AWS_REGION}" \
  --output json | jq '.service | {status, desiredCount, runningCount, pendingCount}'

echo "==> Waiting for ${DEPLOY_SERVICE} to stabilise (may take 2-3 minutes)..."

aws ecs wait services-stable \
  --cluster "${ECS_CLUSTER}" \
  --services "${DEPLOY_SERVICE}" \
  --region "${AWS_REGION}"

echo "==> ${DEPLOY_SERVICE} is stable and running ${DESIRED_COUNT} tasks"
