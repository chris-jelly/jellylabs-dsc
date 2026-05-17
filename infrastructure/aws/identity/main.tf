terraform {
  required_version = "~> 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  github_subject             = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
  github_pr_subject          = "repo:${var.github_repository}:pull_request"
  state_bucket_arn           = "arn:${data.aws_partition.current.partition}:s3:::${var.state_bucket_name}"
  workload_state_key_glob    = "${var.workload_state_key_prefix}/*/global.tfstate"
  workload_state_prefix_glob = "${var.workload_state_key_prefix}/*"
  heartbeat_topic_arn        = "arn:${data.aws_partition.current.partition}:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:homelab-uptime-alerts"
  heartbeat_secret_arn       = "arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.lab_resource_prefix}homelab-heartbeat-token-*"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints
}

data "aws_iam_policy_document" "main_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }
  }
}

resource "aws_iam_role" "main" {
  name               = var.main_role_name
  assume_role_policy = data.aws_iam_policy_document.main_assume_role.json
}

data "aws_iam_policy_document" "plan_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_pr_subject]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = var.plan_role_name
  assume_role_policy = data.aws_iam_policy_document.plan_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "heartbeat_receiver" {
  name               = "${var.lab_role_prefix}heartbeat-receiver"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "heartbeat_checker" {
  name               = "${var.lab_role_prefix}heartbeat-checker"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "heartbeat_scheduler" {
  name               = "${var.lab_role_prefix}heartbeat-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "heartbeat_receiver" {
  statement {
    sid = "WriteLambdaLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lab_resource_prefix}*:log-stream:*"]
  }

  statement {
    sid = "UpdateHeartbeatRegistry"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.lab_resource_prefix}*"]
  }
}

data "aws_iam_policy_document" "heartbeat_checker" {
  statement {
    sid = "WriteLambdaLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lab_resource_prefix}*:log-stream:*"]
  }

  statement {
    sid = "ReadAndUpdateHeartbeatRegistry"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.lab_resource_prefix}*"]
  }

  statement {
    sid       = "PublishUptimeAlerts"
    actions   = ["sns:Publish"]
    resources = [local.heartbeat_topic_arn]
  }
}

data "aws_iam_policy_document" "heartbeat_receiver_recovery_alerts" {
  statement {
    sid       = "PublishRecoveryAlerts"
    actions   = ["sns:Publish"]
    resources = [local.heartbeat_topic_arn]
  }
}

data "aws_iam_policy_document" "heartbeat_receiver_token_secret" {
  statement {
    sid       = "ReadHeartbeatTokenSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [local.heartbeat_secret_arn]
  }
}

data "aws_iam_policy_document" "heartbeat_scheduler" {
  statement {
    sid       = "InvokeHeartbeatChecker"
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.lab_resource_prefix}*"]
  }
}

data "aws_iam_policy_document" "heartbeat_receiver_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.heartbeat_receiver.json,
    data.aws_iam_policy_document.heartbeat_receiver_recovery_alerts.json,
    data.aws_iam_policy_document.heartbeat_receiver_token_secret.json,
  ]
}

resource "aws_iam_role_policy" "heartbeat_receiver" {
  name   = "${var.lab_role_prefix}heartbeat-receiver-policy"
  role   = aws_iam_role.heartbeat_receiver.id
  policy = data.aws_iam_policy_document.heartbeat_receiver_combined.json
}

resource "aws_iam_role_policy" "heartbeat_checker" {
  name   = "${var.lab_role_prefix}heartbeat-checker-policy"
  role   = aws_iam_role.heartbeat_checker.id
  policy = data.aws_iam_policy_document.heartbeat_checker.json
}

resource "aws_iam_role_policy" "heartbeat_scheduler" {
  name   = "${var.lab_role_prefix}heartbeat-scheduler-policy"
  role   = aws_iam_role.heartbeat_scheduler.id
  policy = data.aws_iam_policy_document.heartbeat_scheduler.json
}

data "aws_iam_policy_document" "main" {
  statement {
    sid       = "MainStateBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "MainStateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.workload_state_key_glob,
        local.workload_state_prefix_glob,
      ]
    }
  }

  statement {
    sid = "MainStateObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${local.state_bucket_arn}/${local.workload_state_key_glob}"]
  }

  statement {
    sid = "MainStateLockTable"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_lock_table_name}"]
  }

  statement {
    sid = "Budgets"
    actions = [
      "budgets:CreateBudget",
      "budgets:DeleteBudget",
      "budgets:DescribeBudget",
      "budgets:DescribeBudgets",
      "budgets:ModifyBudget",
      "budgets:UpdateBudget",
      "budgets:CreateNotification",
      "budgets:DeleteNotification",
      "budgets:DescribeNotificationsForBudget",
      "budgets:UpdateNotification",
      "budgets:CreateSubscriber",
      "budgets:DeleteSubscriber",
      "budgets:DescribeSubscribersForNotification",
      "budgets:UpdateSubscriber",
    ]
    resources = ["*"]
  }

  statement {
    sid = "SnsUptimeAlertTopic"
    actions = [
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:ListTagsForResource",
      "sns:TagResource",
      "sns:UntagResource",
      "sns:Subscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish",
    ]
    resources = [local.heartbeat_topic_arn]
  }

  statement {
    sid = "SnsUptimeAlertSubscriptions"
    actions = [
      "sns:GetSubscriptionAttributes",
      "sns:SetSubscriptionAttributes",
      "sns:Unsubscribe",
    ]
    resources = ["*"]
  }

  statement {
    sid = "DynamoDbHeartbeat"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateTable",
      "dynamodb:UpdateTimeToLive",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "LambdaHeartbeat"
    actions = [
      "lambda:AddPermission",
      "lambda:CreateFunction",
      "lambda:CreateFunctionUrlConfig",
      "lambda:DeleteFunction",
      "lambda:DeleteFunctionUrlConfig",
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetFunctionUrlConfig",
      "lambda:GetPolicy",
      "lambda:ListVersionsByFunction",
      "lambda:RemovePermission",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateFunctionUrlConfig",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "EventBridgeHeartbeat"
    actions = [
      "events:DeleteRule",
      "events:DescribeRule",
      "events:ListTagsForResource",
      "events:ListTargetsByRule",
      "events:PutRule",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:TagResource",
      "events:UntagResource",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "SchedulerHeartbeat"
    actions = [
      "scheduler:CreateSchedule",
      "scheduler:DeleteSchedule",
      "scheduler:GetSchedule",
      "scheduler:ListTagsForResource",
      "scheduler:TagResource",
      "scheduler:UntagResource",
      "scheduler:UpdateSchedule",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "CloudWatchLogsHeartbeat"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lab_resource_prefix}*"]
  }

  statement {
    sid       = "CreateHeartbeatTokenSecret"
    actions   = ["secretsmanager:CreateSecret"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "secretsmanager:Name"
      values   = ["${var.lab_resource_prefix}homelab-heartbeat-token"]
    }
  }

  statement {
    sid = "ManageHeartbeatTokenSecretMetadata"
    actions = [
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
      "secretsmanager:UpdateSecret",
    ]
    resources = [local.heartbeat_secret_arn]
  }

  statement {
    sid = "ReadLabExecutionRoles"
    actions = [
      "iam:GetRole",
    ]
    resources = [
      aws_iam_role.heartbeat_receiver.arn,
      aws_iam_role.heartbeat_checker.arn,
      aws_iam_role.heartbeat_scheduler.arn,
    ]
  }

  statement {
    sid     = "PassHeartbeatLambdaRoles"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.heartbeat_receiver.arn,
      aws_iam_role.heartbeat_checker.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid       = "PassHeartbeatSchedulerRole"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.heartbeat_scheduler.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "main" {
  name   = "${var.main_role_name}-policy"
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.main.json
}

data "aws_iam_policy_document" "plan" {
  statement {
    sid       = "PlanStateBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "PlanStateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.workload_state_key_glob,
        local.workload_state_prefix_glob,
      ]
    }
  }

  statement {
    sid       = "PlanStateObjectsRead"
    actions   = ["s3:GetObject"]
    resources = ["${local.state_bucket_arn}/${local.workload_state_key_glob}"]
  }

  statement {
    sid = "PlanStateLockTable"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_lock_table_name}"]
  }

  statement {
    sid = "PlanBudgetsRead"
    actions = [
      "budgets:DescribeBudget",
      "budgets:DescribeBudgets",
      "budgets:DescribeNotificationsForBudget",
      "budgets:DescribeSubscribersForNotification",
      "budgets:ViewBudget",
    ]
    resources = ["*"]
  }

  statement {
    sid = "PlanSnsTopicRead"
    actions = [
      "sns:GetTopicAttributes",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTagsForResource",
    ]
    resources = [local.heartbeat_topic_arn]
  }

  statement {
    sid       = "PlanSnsSubscriptionRead"
    actions   = ["sns:GetSubscriptionAttributes"]
    resources = ["*"]
  }

  statement {
    sid = "PlanDynamoDbRead"
    actions = [
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:GetItem",
      "dynamodb:ListTagsOfResource",
      "dynamodb:Scan",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "PlanLambdaRead"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetFunctionUrlConfig",
      "lambda:GetPolicy",
      "lambda:ListVersionsByFunction",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "PlanEventBridgeRead"
    actions = [
      "events:DescribeRule",
      "events:ListTagsForResource",
      "events:ListTargetsByRule",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "PlanSchedulerRead"
    actions = [
      "scheduler:GetSchedule",
      "scheduler:ListTagsForResource",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "PlanCloudWatchLogsRead"
    actions = [
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lab_resource_prefix}*"]
  }

  statement {
    sid = "PlanSecretsManagerRead"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [local.heartbeat_secret_arn]
  }

  statement {
    sid     = "PlanReadLabExecutionRoles"
    actions = ["iam:GetRole"]
    resources = [
      aws_iam_role.heartbeat_receiver.arn,
      aws_iam_role.heartbeat_checker.arn,
      aws_iam_role.heartbeat_scheduler.arn,
    ]
  }
}

resource "aws_iam_role_policy" "plan" {
  name   = "${var.plan_role_name}-policy"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan.json
}
