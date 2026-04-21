# ═══════════════════════════════════════════════════════════════════
# outputs.tf – Reference for CI/CD mapping (no Terraform outputs here)
# ═══════════════════════════════════════════════════════════════════

# NOTE:
# All real outputs are defined in:
#   - alb.tf
#   - ecs.tf
#   - ecr.tf
#   - iam.tf
#   - monitoring.tf
#
# This file is ONLY documentation for GitHub Actions mapping.

# ─────────────────────────────────────────────────────────────────
# GitHub Actions variable map (must match Terraform outputs)
# ─────────────────────────────────────────────────────────────────
# AWS_REGION             → manually set in GitHub Actions
# ECR_REPOSITORY         → ecr_repository_url
# ECS_CLUSTER            → ecs_cluster_name
# BLUE_SERVICE           → blue_service_name
# GREEN_SERVICE          → green_service_name
# BLUE_TG_ARN            → blue_target_group_arn
# GREEN_TG_ARN           → green_target_group_arn
# ALB_LISTENER_ARN       → alb_listener_arn
# TEST_LISTENER_ARN      → test_listener_arn
# ALB_DNS_NAME           → alb_dns_name
# DESIRED_COUNT          → manually set in GitHub Actions
# ─────────────────────────────────────────────────────────────────