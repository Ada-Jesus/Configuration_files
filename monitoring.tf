# ═══════════════════════════════════════════════════════════════════
#  monitoring.tf  –  CloudWatch alarms, dashboard, SNS notifications
# ═══════════════════════════════════════════════════════════════════

# ── SNS Topic ─────────────────────────────────────────────────────
resource "aws_sns_topic" "deployments" {
  name = "${local.name_prefix}-deployments"
}

# Add an email subscription (update address before applying)
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.deployments.arn
#   protocol  = "email"
#   endpoint  = "your-team@example.com"
# }

# ── Alarms: Unhealthy hosts ───────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "unhealthy_blue" {
  alarm_name          = "${local.name_prefix}-blue-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 30
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Blue TG has unhealthy hosts – potential rollback trigger"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
  }

  alarm_actions = [aws_sns_topic.deployments.arn]
  ok_actions    = [aws_sns_topic.deployments.arn]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_green" {
  alarm_name          = "${local.name_prefix}-green-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 30
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Green TG has unhealthy hosts – potential rollback trigger"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.green.arn_suffix
  }

  alarm_actions = [aws_sns_topic.deployments.arn]
  ok_actions    = [aws_sns_topic.deployments.arn]
}

# ── Alarm: 5xx error rate ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_description   = "More than 10 5xx errors in 60s – investigate or rollback"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [aws_sns_topic.deployments.arn]
}

# ── Alarm: High response time ─────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${local.name_prefix}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p95"
  threshold           = 2
  treat_missing_data  = "notBreaching"
  alarm_description   = "p95 response time exceeds 2s"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [aws_sns_topic.deployments.arn]
}

# ── CloudWatch Dashboard ──────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-deployments"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title = "Request Count & Error Rates"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount",              "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title = "Target Group Healthy Hosts"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.blue.arn_suffix,  "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.green.arn_suffix, "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          period = 30
          stat   = "Average"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title = "ECS CPU Utilization"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.blue.name,  "ClusterName", aws_ecs_cluster.main.name],
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.green.name, "ClusterName", aws_ecs_cluster.main.name]
          ]
          period = 60
          stat   = "Average"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title = "p95 Response Time"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          period    = 60
          stat      = "p95"
          view      = "timeSeries"
        }
      }
    ]
  })
}

output "sns_topic_arn" {
  description = "SNS topic ARN for deployment notifications"
  value       = aws_sns_topic.deployments.arn
}

output "cloudwatch_dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
