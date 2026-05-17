output "heartbeat_receiver_url" {
  description = "Lambda Function URL for the homelab heartbeat receiver."
  value       = aws_lambda_function_url.receiver.function_url
}

output "heartbeat_registry_table_name" {
  description = "DynamoDB table that stores heartbeat state keyed by service_id."
  value       = aws_dynamodb_table.heartbeat_registry.name
}

output "uptime_alerts_topic_arn" {
  description = "SNS topic ARN for homelab uptime email and SMS alerts."
  value       = aws_sns_topic.uptime_alerts.arn
}

output "heartbeat_token_secret_arn" {
  description = "Secrets Manager secret ARN that must contain the shared heartbeat token value."
  value       = aws_secretsmanager_secret.heartbeat_token.arn
}

output "homelab_heartbeat_interval_minutes" {
  description = "Expected homelab CronJob interval in minutes."
  value       = var.heartbeat_interval_minutes
}
