# ═══════════════════════════════════════════════════════════════════
#  outputs.tf  –  Consolidated outputs for GitHub Actions variables
#
#  After `terraform apply`, run:
#    terraform output -json | jq 'to_entries[] | "\(.key)=\(.value.value)"' -r
#  to get all values ready to paste into GitHub Actions variables.
# ═══════════════════════════════════════════════════════════════════

# All outputs are defined in their respective resource files.
# This file exists as a reference / documentation layer only.
#
# GitHub Actions variable map:
# ─────────────────────────────────────────────────────────────────
# Variable name          → Terraform output
# ─────────────────────────────────────────────────────────────────
# AWS_REGION             → (set manually, e.g. us-east-1)
# ECR_REPOSITORY         → ecr_repository_url
# ECS_CLUSTER            → ecs_cluster_name
# BLUE_SERVICE           → blue_service_name
# GREEN_SERVICE          → green_service_name
# BLUE_TG_ARN            → blue_target_group_arn
# GREEN_TG_ARN           → green_target_group_arn
# ALB_LISTENER_ARN       → alb_listener_arn
# TEST_LISTENER_ARN      → test_listener_arn
# ALB_DNS_NAME           → alb_dns_name
# DESIRED_COUNT          → (set manually, e.g. 2)
# ─────────────────────────────────────────────────────────────────
