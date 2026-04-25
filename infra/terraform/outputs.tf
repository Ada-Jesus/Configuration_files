output "alb_dns" {
  value = aws_lb.main.dns_name
}

output "ecr_url" {
  value = aws_ecr_repository.app.repository_url
}

output "sns_topic" {
  value = aws_sns_topic.deployments.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "blue_tg" {
  value = aws_lb_target_group.blue.arn
}

output "green_tg" {
  value = aws_lb_target_group.green.arn
}