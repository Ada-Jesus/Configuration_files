resource "aws_sns_topic" "deployments" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-5xx"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  evaluation_periods  = 2
  period              = 60
  statistic           = "Sum"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [aws_sns_topic.deployments.arn]
}