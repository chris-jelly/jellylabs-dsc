## Why

The AWS bootstrap stack is the root of trust and was already applied manually with operator admin credentials. Keeping bootstrap OIDC deployment in GitHub blurs that boundary and leaves the normal AWS lab stack without a clear least-privilege CI role.

## What Changes

- Remove GitHub Actions OIDC provider, bootstrap deployment role, role policy, role output, and automatic bootstrap apply workflow behavior from the AWS bootstrap scope.
- Keep the bootstrap stack focused on manually applied remote-state primitives: the S3 state bucket and DynamoDB lock table.
- Add a separate AWS main OpenTofu deployment identity for normal lab infrastructure, trusted by GitHub Actions from this repository's `main` branch.
- Define the initial AWS main deployment policy needed by the pending `add-aws-guardrails-and-homelab-heartbeat` change, including Budgets, SNS, DynamoDB, Lambda, EventBridge scheduling/rules, CloudWatch Logs, and constrained pass-role access for identity-managed heartbeat execution roles.
- Require AWS main resources to use a separate remote-state key and GitHub repository variable, such as `AWS_MAIN_ROLE_ARN`, instead of the bootstrap role ARN.
- Keep bootstrap changes manually applied with operator admin credentials, or through a later protected manual workflow if needed.

## Capabilities

### New Capabilities

- `aws-main-oidc-deployment`: Defines the GitHub OIDC deploy role, trust boundary, remote-state usage, and initial least-privilege permissions for the AWS main lab stack.

### Modified Capabilities

- `aws-bootstrap-foundation`: Narrows bootstrap from state plus CI identity to manual remote-state foundation only.

## Impact

- Updates `infrastructure/aws/bootstrap` by removing OIDC/IAM deployment resources and related outputs/variables/docs.
- Updates GitHub Actions workflows so bootstrap is validated but not auto-applied from GitHub OIDC.
- Adds or updates the AWS main stack and workflow to assume a new main deploy role for normal lab resources.
- Requires one manual bootstrap/admin apply to remove obsolete bootstrap OIDC resources and create or update the AWS main deploy role.
- Requires the pending `add-aws-guardrails-and-homelab-heartbeat` change to target the AWS main deployment path and use the main deploy role permissions defined by this change.
