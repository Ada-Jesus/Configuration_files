# ═══════════════════════════════════════════════════════════════════
# vpc_endpoints.tf – ECS networking fix (SSM, ECR, Secrets Manager)
# Fixes: ResourceInitializationError in ECS tasks
# ═══════════════════════════════════════════════════════════════════

# ── SSM Parameter Store Endpoint ──────────────────────────────────
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.ecs_tasks.id]

  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-ssm-endpoint"
  }
}

# ── Secrets Manager Endpoint ──────────────────────────────────────
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.ecs_tasks.id]

  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-secretsmanager-endpoint"
  }
}

# ── ECR API Endpoint ──────────────────────────────────────────────
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.ecs_tasks.id]

  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-ecr-api-endpoint"
  }
}

# ── ECR Docker Endpoint ───────────────────────────────────────────
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.ecs_tasks.id]

  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-ecr-dkr-endpoint"
  }
}

# ── CloudWatch Logs Endpoint (recommended) ────────────────────────
resource "aws_vpc_endpoint" "logs" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.ecs_tasks.id]

  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-logs-endpoint"
  }
}