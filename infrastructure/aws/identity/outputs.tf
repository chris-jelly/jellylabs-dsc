output "main_role_arn" {
  value = aws_iam_role.main.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "heartbeat_receiver_role_arn" {
  value = aws_iam_role.heartbeat_receiver.arn
}

output "heartbeat_checker_role_arn" {
  value = aws_iam_role.heartbeat_checker.arn
}

output "heartbeat_scheduler_role_arn" {
  value = aws_iam_role.heartbeat_scheduler.arn
}
