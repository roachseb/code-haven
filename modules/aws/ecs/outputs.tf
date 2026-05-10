output "url" {
  description = "ALB DNS name (HTTP endpoint)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.main.name
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "task_definition_arn" {
  description = "ARN of the current task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.main.name
}
