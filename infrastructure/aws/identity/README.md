# AWS Identity

This root defines the GitHub Actions OIDC trust, AWS main deployment role for normal AWS lab OpenTofu applies, and AWS plan role for pull request planning.

Apply this root manually with operator admin credentials after bootstrap creates the remote-state bucket and lock table. GitHub Actions does not apply this root because the deployment role should not manage its own trust or permissions.

## Included

- GitHub Actions OIDC provider for `token.actions.githubusercontent.com`
- Main deployment role trusted by the `chris-jelly/jellylabs-dsc` `aws-production` GitHub Environment
- Pull request plan role trusted by `chris-jelly/jellylabs-dsc` pull request workflows
- Initial main deployment policy for AWS state access, Budgets, SNS, DynamoDB, Lambda, EventBridge, Scheduler, CloudWatch Logs, and constrained role passing
- Plan role policy for workload state reads, state locking during planning, and read/list/describe access for supported AWS lab resources
- Manually managed heartbeat receiver, checker, and scheduler execution roles

## Manual apply path

1. Copy `backend.tf.example` to `backend.tf` and `backend.hcl.example` to `backend.hcl`.
2. Set the real state bucket in `backend.hcl`.
3. Copy `local.auto.tfvars.example` to `local.auto.tfvars` and set the real bootstrap state bucket name. The local file is gitignored and prevents repeated `state_bucket_name` prompts during manual plans.
4. Run `tofu init -backend-config=backend.hcl`.
5. Run `tofu plan`.
6. Run `tofu apply` after review.
7. Store the `main_role_arn` output as the GitHub repository variable `AWS_MAIN_ROLE_ARN`.
8. Store the `plan_role_arn` output as the GitHub repository variable `AWS_PLAN_ROLE_ARN`.
9. Configure the `aws-production` GitHub Environment for apply jobs. Restrict deployments to `main` and add required reviewers if production applies should wait for approval.

## Permission model

The main deployment role starts with the permissions needed by the pending guardrails and heartbeat lab. Expand the role only through reviewed infrastructure changes when new AWS service families are added.

`iam:PassRole` is constrained to the execution roles defined in this root. Receiver and checker roles can be passed only to Lambda, and the scheduler role can be passed only to Scheduler. The main deployment role does not create arbitrary IAM roles or policies.

The plan role is separate from the main deployment role. It is trusted only for pull request workflows and grants workload state reads, lock-table access needed during planning, and read/list/describe access for supported workload resources. It should not gain create, update, or delete permissions for workload resources unless a future planning edge case is reviewed explicitly.

Manual-root planning remains outside the workload CI workflow. If `bootstrap/` or `identity/` needs CI plan visibility later, use a separate plan-only workflow with its own credentials and approval model.
