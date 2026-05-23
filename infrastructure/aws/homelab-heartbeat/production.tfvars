# Production configuration for the homelab heartbeat AWS root.
#
# Replace the placeholder email addresses before applying. These values are
# intentionally versioned with the root instead of being wired into the shared
# GitHub Actions workflow as root-specific TF_VAR_* mappings.

budget_alert_email_addresses = [
  "christopher.p.jelly@gmail.com",
]

uptime_alert_email_addresses = [
  "christopher.p.jelly@gmail.com",
]

uptime_alert_sms_numbers = ["+19054100131"]

heartbeat_service_id          = "homelab-cluster"
heartbeat_interval_minutes    = 5
stale_after_seconds           = 900
checker_schedule_expression   = "rate(5 minutes)"
alert_reminder_seconds        = 21600
send_recovery_notifications   = true
log_retention_days            = 14
heartbeat_token_secret_name   = "jellylabs-homelab-heartbeat-token"
heartbeat_token_secret_source = "Set this secret value outside OpenTofu, for example from GitHub Actions or an operator workstation."
