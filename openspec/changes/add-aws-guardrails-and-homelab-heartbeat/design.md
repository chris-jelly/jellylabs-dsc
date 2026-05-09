## Context

The AWS bootstrap foundation is intentionally limited to manually applied remote state. A separate AWS main GitHub OIDC deployment role applies normal AWS lab workload roots. This change is the next AWS lab layer in a deployable workload root: first add low-dollar account safety, then add a practical internal-liveness heartbeat for the homelab.

The homelab is deployed through Flux in `~/git/homelab` and already uses Kubernetes app manifests, CronJobs, External Secrets, and GitOps layering. The heartbeat sender should fit that model instead of introducing a long-running service.

The uptime goal is internal liveness, not external reachability. A successful heartbeat means the homelab is alive enough to run a scheduled Kubernetes job and make outbound requests to AWS.

## Goals / Non-Goals

**Goals:**

- Keep normal AWS lab cost near free and alert before monthly spend exceeds $5.
- Use AWS Budgets native email notifications for budget alerts.
- Use SNS only for operational uptime alerts.
- Track heartbeat state for multiple reusable heartbeat sources, starting with `homelab-cluster`.
- Send uptime alerts through SNS email and SMS subscriptions.
- Suppress repeated outage notifications and optionally send recovery notifications.
- Deploy the homelab sender as a Kubernetes CronJob managed by the homelab GitOps workflow.

**Non-Goals:**

- Mobile push notifications.
- Public homelab reachability checks from AWS.
- Monitoring Cloudflare Tunnel, Traefik ingress, or individual public services.
- Long-running AWS compute or homelab application services.
- SMS delivery for budget alerts.

## Decisions

### Use AWS Budgets native email notifications for cost alerts

Create a monthly cost budget with a $5 limit and email subscribers on budget notifications. Use actual-spend thresholds for early warning and a forecasted threshold for projected overruns.

Alternatives considered:

- **Budget alerts through SNS:** Supported, but unnecessary for a single operator email workflow and risks mixing cost alerts with operational alerting.
- **No budget resource:** Simpler, but weakens the safety-first goal of the lab.

### Keep budget and uptime alerting separate

Budget alerts are handled by AWS Budgets. Uptime alerts use a dedicated `homelab-uptime-alerts` SNS topic with email and SMS subscriptions.

Alternatives considered:

- **One SNS topic for all alerts:** Easier to wire, but budget and uptime alerts have different urgency, subscriber preferences, and cost implications.

### Model heartbeat monitoring as a reusable registry

Use a DynamoDB table keyed by `service_id`. Each enabled service stores heartbeat and alert state, including at least:

- `service_id`
- `last_seen_at`
- `stale_after_seconds`
- `status`
- `last_alerted_at`
- `last_recovered_at`
- `enabled`

The first configured service is `homelab-cluster`. Later services can reuse the same receiver and checker with different intervals and stale thresholds.

Alternatives considered:

- **Single hard-coded heartbeat:** Fastest first implementation, but would require redesign to monitor backups, sync jobs, or other future dead-man sources.
- **Separate resources per heartbeat source:** Clear isolation, but too much duplicated infrastructure for a lab.

### Use a serverless AWS receiver and checker

Expose a lightweight heartbeat receiver through API Gateway or a Lambda Function URL. The receiver validates the request, updates DynamoDB, and returns a simple success response. An EventBridge schedule invokes a checker Lambda that scans enabled heartbeat records and publishes to SNS when a record is stale.

Alternatives considered:

- **SQS ingestion:** Good eventing practice, but introduces AWS credentials into the homelab sender and adds a queue where synchronous success is enough.
- **CloudWatch custom metrics and alarms:** Useful, but less direct for reusable per-service state and alert suppression.

### Authenticate heartbeats with a shared secret token

The homelab CronJob sends a secret token with each heartbeat request. The AWS receiver validates the token before updating state. The token is stored using the homelab External Secrets pattern and supplied to the AWS receiver through secure configuration.

Alternatives considered:

- **AWS IAM credentials in homelab:** More AWS-native, but heavier secret handling and permission management for a simple outbound heartbeat.
- **Unauthenticated endpoint:** Simpler, but allows arbitrary callers to spoof liveness.

### Deploy the homelab sender as a CronJob

The homelab side should be a Kubernetes CronJob that periodically posts the `homelab-cluster` heartbeat. It does not need a Service or Ingress.

Alternatives considered:

- **Long-running Deployment:** Useful if local metrics or an HTTP endpoint are needed later, but unnecessary for periodic internal liveness.

## Risks / Trade-offs

- **False positive during planned homelab maintenance** → Use a stale window larger than the CronJob interval and document how to disable the service or suppress alerts during maintenance.
- **Repeated SMS spam during an outage** → Store alert state and suppress repeated notifications until a reminder interval or recovery event.
- **SMS costs vary and can surprise** → Keep SMS only on the uptime topic and rely on AWS's low default SMS spending controls unless explicitly changed.
- **Heartbeat endpoint token leaks** → Treat the token as a secret, store it through existing secret-management paths, and rotate it if exposed.
- **Receiver is reachable by the public internet** → Validate the token, keep the receiver minimal, and log failed requests without exposing sensitive details.
- **DynamoDB scan grows over time** → Accept scan for the initial small registry; revisit indexes only if heartbeat source count grows enough to matter.
- **Budget alerts are not enforcement** → Make clear that the budget notifies but does not prevent spend; avoid known non-free services in lab design.

## Migration Plan

1. Apply or verify the AWS bootstrap foundation so remote state is available.
2. Apply or verify the AWS identity root so the AWS main GitHub OIDC deployment role has the permissions required by this change.
3. Deploy AWS cost guardrails in a deployable AWS workload root: budget, notification subscribers, and tagging conventions.
4. Deploy uptime alerting infrastructure in the same deployable AWS workload root: SNS topic/subscriptions, DynamoDB table, receiver, checker, schedules, identity-managed execution role references, and logs.
5. Confirm email and SMS subscriptions where AWS requires manual confirmation or verification.
6. Add the homelab CronJob and required ExternalSecret-backed configuration.
7. Test by sending a heartbeat, then pausing or disabling the CronJob long enough to trigger stale detection.
8. Roll back by disabling the homelab CronJob and destroying the uptime stack; retain budget guardrails unless intentionally removing the AWS lab.

## Open Questions

- Which email address should receive budget alerts?
- Which email address and phone number should receive uptime alerts?
- Should recovery notifications go to both email and SMS, or email only?
- What exact heartbeat interval and stale threshold should be used initially, for example 5-minute heartbeat and 15-minute stale threshold?
