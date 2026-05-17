variable "aws_region" {
  description = "AWS region for regional heartbeat resources."
  type        = string
  default     = "ca-central-1"
}

variable "state_bucket_name" {
  description = "Bootstrap-managed S3 bucket used by AWS workload OpenTofu state."
  type        = string
}

variable "identity_state_key" {
  description = "S3 key for the manually applied identity root state."
  type        = string
  default     = "aws/identity/global.tfstate"
}

variable "resource_prefix" {
  description = "Name prefix for AWS lab resources. Must match the identity root lab resource prefix."
  type        = string
  default     = "jellylabs-"
}

variable "lab_name" {
  description = "Lab identifier used in tags."
  type        = string
  default     = "jellylabs-dsc"
}

variable "environment" {
  description = "Environment identifier used in resource names and tags."
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owner identifier used in tags."
  type        = string
  default     = "cjelly"
}

variable "cost_center" {
  description = "Cost visibility tag value for lab resources."
  type        = string
  default     = "homelab"
}

variable "budget_alert_email_addresses" {
  description = "Email addresses that receive native AWS Budgets notifications."
  type        = list(string)

  validation {
    condition     = length(var.budget_alert_email_addresses) > 0
    error_message = "At least one budget alert email address is required."
  }
}

variable "uptime_alert_email_addresses" {
  description = "Email addresses subscribed to operational uptime SNS alerts."
  type        = list(string)
  default     = []
}

variable "uptime_alert_sms_numbers" {
  description = "E.164 phone numbers subscribed to operational uptime SNS alerts."
  type        = list(string)
  default     = []
}

variable "heartbeat_token_secret_name" {
  description = "AWS Secrets Manager secret name that stores the shared heartbeat token value. OpenTofu manages secret metadata only. Keep this aligned with the identity root heartbeat secret IAM scope."
  type        = string
  default     = "jellylabs-homelab-heartbeat-token"
}

variable "heartbeat_token_secret_source" {
  description = "Operator-facing note describing how the heartbeat token secret value is populated outside OpenTofu."
  type        = string
  default     = "Set this secret value outside OpenTofu."
}

variable "heartbeat_service_id" {
  description = "Initial homelab heartbeat source identifier."
  type        = string
  default     = "homelab-cluster"
}

variable "heartbeat_interval_minutes" {
  description = "Expected homelab sender interval, used for documentation and outputs."
  type        = number
  default     = 5
}

variable "stale_after_seconds" {
  description = "Seconds after the last heartbeat before the service is considered stale."
  type        = number
  default     = 900
}

variable "checker_schedule_expression" {
  description = "EventBridge Scheduler expression for stale heartbeat checks."
  type        = string
  default     = "rate(5 minutes)"
}

variable "alert_reminder_seconds" {
  description = "Minimum seconds between repeated outage reminders for an ongoing outage."
  type        = number
  default     = 21600
}

variable "send_recovery_notifications" {
  description = "Whether the receiver publishes an SNS recovery notification when a stale service sends a valid heartbeat."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period for heartbeat Lambda functions."
  type        = number
  default     = 14
}
