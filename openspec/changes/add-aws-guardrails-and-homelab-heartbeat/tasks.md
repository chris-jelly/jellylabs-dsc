## 1. AWS Cost Guardrails

- [ ] 1.1 Create or locate the deployable AWS workload root and confirm it uses a root-specific bootstrap remote state key and the AWS main OIDC deployment role.
- [ ] 1.2 Verify the AWS main deploy role includes the permissions needed for Budgets, SNS, DynamoDB, Lambda, EventBridge or Scheduler, CloudWatch Logs, and constrained pass-role access to identity-managed heartbeat execution roles.
- [ ] 1.3 Add common AWS lab tags for lab, environment, ownership, and cost visibility.
- [ ] 1.4 Create a $5 monthly AWS cost budget with native email subscribers.
- [ ] 1.5 Configure actual-spend budget notifications below the limit and at the limit.
- [ ] 1.6 Configure a forecasted-spend budget notification for projected monthly spend above the limit.
- [ ] 1.7 Verify budget alerting does not require SMS subscriptions.

## 2. Uptime Alerting Infrastructure

- [ ] 2.1 Create the `homelab-uptime-alerts` SNS topic for operational uptime alerts.
- [ ] 2.2 Add email and SMS subscriptions for the uptime SNS topic.
- [ ] 2.3 Create the DynamoDB heartbeat registry table keyed by `service_id`.
- [ ] 2.4 Define the initial `homelab-cluster` heartbeat source with enabled state and stale-threshold configuration.
- [ ] 2.5 Use the identity-managed heartbeat receiver, checker, and scheduler execution roles instead of creating IAM roles in the workload root.
- [ ] 2.6 Configure CloudWatch Logs retention for heartbeat receiver and checker functions.

## 3. Heartbeat Receiver

- [ ] 3.1 Implement the serverless heartbeat receiver function.
- [ ] 3.2 Expose the receiver through API Gateway or a Lambda Function URL.
- [ ] 3.3 Validate heartbeat authentication before updating registry state.
- [ ] 3.4 Update `last_seen_at` and recovery-related state for valid heartbeat requests.
- [ ] 3.5 Reject invalid or unauthenticated heartbeat requests without updating state.

## 4. Stale Heartbeat Checker

- [ ] 4.1 Implement the scheduled checker function that evaluates enabled heartbeat sources.
- [ ] 4.2 Add an EventBridge schedule to invoke the checker at the configured interval.
- [ ] 4.3 Publish an outage alert to SNS when a service first transitions to stale.
- [ ] 4.4 Suppress repeated outage alerts until a configured reminder interval elapses.
- [ ] 4.5 Detect recovered services and update status back to healthy.
- [ ] 4.6 Implement the configured recovery-notification behavior.

## 5. Homelab CronJob Sender

- [ ] 5.1 Add homelab GitOps manifests for a heartbeat sender CronJob.
- [ ] 5.2 Configure the CronJob to send the `homelab-cluster` service identifier on the chosen interval.
- [ ] 5.3 Source the receiver endpoint and authentication token from the homelab secret-management pattern.
- [ ] 5.4 Add the heartbeat sender to the appropriate homelab app or production kustomization path.

## 6. Validation

- [ ] 6.1 Run OpenTofu formatting and validation for the AWS lab stack.
- [ ] 6.2 Run relevant function unit tests or local checks for receiver and checker logic.
- [ ] 6.3 Confirm SNS email and SMS subscriptions are pending confirmation or confirmed as expected.
- [ ] 6.4 Send a test heartbeat and verify DynamoDB records `last_seen_at` for `homelab-cluster`.
- [ ] 6.5 Simulate a stale heartbeat and verify one outage alert is published.
- [ ] 6.6 Verify repeated checker runs do not spam duplicate outage alerts.
- [ ] 6.7 Resume heartbeats and verify recovery state is recorded.
- [ ] 6.8 Run OpenSpec validation for `add-aws-guardrails-and-homelab-heartbeat`.
