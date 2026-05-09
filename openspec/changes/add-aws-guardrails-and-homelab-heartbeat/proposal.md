## Why

The AWS lab needs low-cost account guardrails before adding workloads, and the homelab would benefit from a simple dead-man alert that detects when the cluster is no longer alive enough to run scheduled jobs and reach AWS. This change combines a near-free AWS safety baseline with a practical serverless heartbeat lab that exercises SNS, Lambda, DynamoDB, EventBridge, IAM, and OpenTofu patterns without long-running cloud compute.

## What Changes

- Add an AWS monthly cost budget capped at $5 with native email notifications at meaningful actual and forecasted thresholds.
- Add reusable tagging conventions for AWS lab resources so cost and ownership remain visible.
- Add an operational SNS topic for homelab uptime alerts with email and SMS subscriptions.
- Add a reusable heartbeat registry that can track multiple heartbeat sources over time, starting with `homelab-cluster`.
- Add a serverless heartbeat receiver that records the latest heartbeat for a service.
- Add a scheduled stale-heartbeat checker that publishes uptime alerts when an enabled heartbeat source has not reported within its allowed window.
- Add alert suppression and recovery behavior so outages do not spam repeated SMS notifications.
- Add a homelab Kubernetes CronJob that sends the `homelab-cluster` heartbeat on a fixed interval.
- Exclude mobile push notifications and public homelab reachability checks from this change.

## Capabilities

### New Capabilities
- `aws-lab-cost-guardrails`: AWS lab budget, budget notification, and tagging requirements for keeping lab usage near-free.
- `homelab-heartbeat-alerting`: Reusable dead-man heartbeat monitoring for internal homelab liveness with SNS email and SMS alerting.

### Modified Capabilities

- None.

## Impact

- Adds AWS lab infrastructure managed by OpenTofu in a deployable AWS workload root, using bootstrap remote state and the separate AWS main GitHub OIDC deployment role.
- Adds AWS resources for Budgets, SNS, DynamoDB, Lambda, EventBridge Scheduler or rules, identity-managed execution role references, and CloudWatch Logs.
- Adds homelab GitOps resources in `~/git/homelab`, likely as an app-style Kubernetes CronJob with ExternalSecret-backed configuration.
- Requires operator-provided contact endpoints for budget email, uptime email, and uptime SMS.
- Requires a shared heartbeat token or equivalent secret stored through the homelab secret-management pattern and referenced by the AWS receiver.
