# AWS Identity

This root defines the GitHub Actions OIDC trust and AWS main deployment role for normal AWS lab OpenTofu applies.

Apply this root manually with operator admin credentials after bootstrap creates the remote-state bucket and lock table. GitHub Actions does not apply this root because the deployment role should not manage its own trust or permissions.

## Included

- GitHub Actions OIDC provider for `token.actions.githubusercontent.com`
- Main deployment role trusted by `chris-jelly/jellylabs-dsc` on `main`
- Initial main deployment policy for AWS state access, Budgets, SNS, DynamoDB, Lambda, EventBridge, Scheduler, CloudWatch Logs, and constrained role passing
- Manually managed heartbeat receiver, checker, and scheduler execution roles

## Manual apply path

1. Copy `backend.tf.example` to `backend.tf` and `backend.hcl.example` to `backend.hcl`.
2. Set the real state bucket in `backend.hcl`.
3. Run `tofu init -backend-config=backend.hcl`.
4. Run `tofu plan -var="state_bucket_name=<bootstrap-state-bucket>"`.
5. Run `tofu apply -var="state_bucket_name=<bootstrap-state-bucket>"` after review.
6. Store the `main_role_arn` output as the GitHub repository variable `AWS_MAIN_ROLE_ARN`.

## Permission model

The main deployment role starts with the permissions needed by the pending guardrails and heartbeat lab. Expand the role only through reviewed infrastructure changes when new AWS service families are added.

`iam:PassRole` is constrained to the execution roles defined in this root. Receiver and checker roles can be passed only to Lambda, and the scheduler role can be passed only to Scheduler. The main deployment role does not create arbitrary IAM roles or policies.
