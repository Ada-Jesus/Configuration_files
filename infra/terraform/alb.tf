# ═══════════════════════════════════════════════════════════════
# APPLICATION LOAD BALANCER
# ═══════════════════════════════════════════════════════════════

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = false
}

# ═══════════════════════════════════════════════════════════════
# LISTENER (THIS WAS MISSING / BROKEN)
# ═══════════════════════════════════════════════════════════════

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Service Running"
      status_code  = "200"
    }
  }
}

# ═══════════════════════════════════════════════════════════════
# TARGET GROUP - BLUE
# ═══════════════════════════════════════════════════════════════

resource "aws_lb_target_group" "blue" {
  name        = "${local.name_prefix}-blue"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
  }
}

# ═══════════════════════════════════════════════════════════════
# TARGET GROUP - GREEN
# ═══════════════════════════════════════════════════════════════

resource "aws_lb_target_group" "green" {
  name        = "${local.name_prefix}-green"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
  }
}

# ═══════════════════════════════════════════════════════════════
# BLUE LISTENER RULE
# ═══════════════════════════════════════════════════════════════

resource "aws_lb_listener_rule" "blue" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ═══════════════════════════════════════════════════════════════
# GREEN LISTENER RULE
# ═══════════════════════════════════════════════════════════════

resource "aws_lb_listener_rule" "green" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}