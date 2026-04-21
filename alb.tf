# ═══════════════════════════════════════════════════════════════════
#  alb.tf  –  Application Load Balancer, listeners, target groups
# ═══════════════════════════════════════════════════════════════════

# ── S3 bucket for ALB access logs ────────────────────────────────
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${local.name_prefix}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs.arn}/alb/*"
      }
    ]
  })
}

# ── Application Load Balancer ─────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  enable_deletion_protection       = var.alb_deletion_protection
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb"
    enabled = true
  }
}

# ── Target groups (Blue & Green) ──────────────────────────────────
resource "aws_lb_target_group" "blue" {
  name        = "${local.name_prefix}-blue-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    path                = "/health"
    matcher             = "200"
  }

  # Drain connections before deregistering (zero-downtime)
  deregistration_delay = 30

  tags = { Slot = "blue" }
}

resource "aws_lb_target_group" "green" {
  name        = "${local.name_prefix}-green-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    path                = "/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = { Slot = "green" }
}

# ── Listeners ─────────────────────────────────────────────────────

# HTTP – redirects to HTTPS when a cert is provided, else forwards
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.certificate_arn != "" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn == "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.blue.arn
    }
  }
}

# HTTPS (optional – only created when certificate_arn is set)
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# Test listener on port 8080 – pipeline validates new slot here
# before switching live traffic
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}

# ── Outputs ───────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "ALB DNS name – use as ALB_DNS_NAME in GitHub Actions variables"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "blue_target_group_arn" {
  description = "Use as BLUE_TG_ARN in GitHub Actions variables"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "Use as GREEN_TG_ARN in GitHub Actions variables"
  value       = aws_lb_target_group.green.arn
}

output "alb_listener_arn" {
  description = "Use as ALB_LISTENER_ARN in GitHub Actions variables"
  value       = aws_lb_listener.http.arn
}

output "test_listener_arn" {
  description = "Use as TEST_LISTENER_ARN in GitHub Actions variables"
  value       = aws_lb_listener.test.arn
}
