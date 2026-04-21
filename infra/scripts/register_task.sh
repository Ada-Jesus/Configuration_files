#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  register_task.sh  –  Clone current task definition with new image
#
#  Required env vars:
#    ECS_CLUSTER, DEPLOY_SERVICE, IMAGE_URI, AWS_REGION, GITHUB_OUTPUT
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Fetching current task definition for: ${DEPLOY_SERVICE}"

CURRENT_TD=$(aws ecs describe-services \
  --cluster "${ECS_CLUSTER}" \
  --services "${DEPLOY_SERVICE}" \
  --query 'services[0].taskDefinition' \
  --output text \
  --region "${AWS_REGION}")

echo "    Current task definition: ${CURRENT_TD}"
echo "    New image URI:           ${IMAGE_URI}"

# Strip read-only fields and update the container image
NEW_TD=$(aws ecs describe-task-definition \
  --task-definition "${CURRENT_TD}" \
  --query 'taskDefinition' \
  --output json \
  --region "${AWS_REGION}" | \
  jq --arg IMAGE "${IMAGE_URI}" '
    del(
      .taskDefinitionArn,
      .revision,
      .status,
      .requiresAttributes,
      .placementConstraints,
      .compatibilities,
      .registeredAt,
      .registeredBy
    ) |
    .containerDefinitions[0].image = $IMAGE
  ' | \
  aws ecs register-task-definition \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text \
    --region "${AWS_REGION}")

echo "    New task definition ARN: ${NEW_TD}"
echo "task_def_arn=${NEW_TD}" >> "${GITHUB_OUTPUT}"

echo "==> Task definition registered successfully"
