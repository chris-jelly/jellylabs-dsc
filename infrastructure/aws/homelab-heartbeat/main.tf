provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Lab         = var.lab_name
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "OpenTofu"
  }

  name_prefix = "${var.resource_prefix}homelab-heartbeat"
}

data "aws_iam_role" "heartbeat_receiver" {
  name = "${var.lab_role_prefix}heartbeat-receiver"
}

data "aws_iam_role" "heartbeat_checker" {
  name = "${var.lab_role_prefix}heartbeat-checker"
}

data "aws_iam_role" "heartbeat_scheduler" {
  name = "${var.lab_role_prefix}heartbeat-scheduler"
}

data "archive_file" "receiver" {
  type        = "zip"
  source_file = "${path.module}/functions/receiver.py"
  output_path = "${path.module}/build/receiver.zip"
}

data "archive_file" "checker" {
  type        = "zip"
  source_file = "${path.module}/functions/checker.py"
  output_path = "${path.module}/build/checker.zip"
}

resource "aws_budgets_budget" "monthly_lab" {
  name         = "${var.resource_prefix}monthly-lab-cost"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_email_addresses
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_email_addresses
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_email_addresses
  }
}

resource "aws_sns_topic" "uptime_alerts" {
  name = "homelab-uptime-alerts"
}

resource "aws_sns_topic_subscription" "uptime_email" {
  for_each  = toset(var.uptime_alert_email_addresses)
  topic_arn = aws_sns_topic.uptime_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "uptime_sms" {
  for_each  = toset(var.uptime_alert_sms_numbers)
  topic_arn = aws_sns_topic.uptime_alerts.arn
  protocol  = "sms"
  endpoint  = each.value
}

resource "aws_secretsmanager_secret" "heartbeat_token" {
  name        = var.heartbeat_token_secret_name
  description = "Shared token for homelab heartbeat receiver authentication. ${var.heartbeat_token_secret_source}"
}

resource "aws_dynamodb_table" "heartbeat_registry" {
  name         = "${local.name_prefix}-registry"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service_id"

  attribute {
    name = "service_id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "homelab_cluster" {
  table_name = aws_dynamodb_table.heartbeat_registry.name
  hash_key   = aws_dynamodb_table.heartbeat_registry.hash_key

  item = jsonencode({
    service_id = { S = var.heartbeat_service_id }
    enabled    = { BOOL = true }
    status     = { S = "unknown" }
    stale_after_seconds = {
      N = tostring(var.stale_after_seconds)
    }
    alert_reminder_seconds = {
      N = tostring(var.alert_reminder_seconds)
    }
  })

  lifecycle {
    ignore_changes = [item]
  }
}

resource "aws_cloudwatch_log_group" "receiver" {
  name              = "/aws/lambda/${local.name_prefix}-receiver"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "checker" {
  name              = "/aws/lambda/${local.name_prefix}-checker"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "receiver" {
  function_name    = "${local.name_prefix}-receiver"
  role             = data.aws_iam_role.heartbeat_receiver.arn
  handler          = "receiver.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.receiver.output_path
  source_code_hash = data.archive_file.receiver.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      HEARTBEAT_TABLE             = aws_dynamodb_table.heartbeat_registry.name
      HEARTBEAT_TOKEN_SECRET_ARN  = aws_secretsmanager_secret.heartbeat_token.arn
      DEFAULT_STALE_AFTER_SECONDS = tostring(var.stale_after_seconds)
      DEFAULT_REMINDER_SECONDS    = tostring(var.alert_reminder_seconds)
      RECOVERY_TOPIC_ARN          = aws_sns_topic.uptime_alerts.arn
      SEND_RECOVERY_NOTIFICATIONS = tostring(var.send_recovery_notifications)
    }
  }

  depends_on = [aws_cloudwatch_log_group.receiver]
}

resource "aws_lambda_function_url" "receiver" {
  function_name      = aws_lambda_function.receiver.function_name
  authorization_type = "NONE"

  cors {
    allow_methods = ["POST"]
    allow_origins = ["*"]
  }
}

resource "aws_lambda_function" "checker" {
  function_name    = "${local.name_prefix}-checker"
  role             = data.aws_iam_role.heartbeat_checker.arn
  handler          = "checker.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.checker.output_path
  source_code_hash = data.archive_file.checker.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      HEARTBEAT_TABLE          = aws_dynamodb_table.heartbeat_registry.name
      UPTIME_TOPIC_ARN         = aws_sns_topic.uptime_alerts.arn
      DEFAULT_REMINDER_SECONDS = tostring(var.alert_reminder_seconds)
    }
  }

  depends_on = [aws_cloudwatch_log_group.checker]
}

resource "aws_scheduler_schedule" "checker" {
  name                         = "${local.name_prefix}-checker"
  schedule_expression          = var.checker_schedule_expression
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.checker.arn
    role_arn = data.aws_iam_role.heartbeat_scheduler.arn
  }
}

resource "aws_lambda_permission" "allow_function_url" {
  statement_id           = "AllowPublicFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.receiver.function_name
  principal              = "*"
  function_url_auth_type = aws_lambda_function_url.receiver.authorization_type
}
