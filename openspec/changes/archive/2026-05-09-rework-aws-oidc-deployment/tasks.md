## 1. Bootstrap Scope Cleanup

- [x] 1.1 Remove GitHub OIDC provider, bootstrap GitHub Actions IAM role, inline role policy, and related IAM policy documents from `infrastructure/aws/bootstrap`.
- [x] 1.2 Remove bootstrap OIDC variables and outputs, including role name, thumbprints, and role ARN output.
- [x] 1.3 Update bootstrap documentation to state that bootstrap is manually applied with operator admin credentials and owns only remote state resources.
- [x] 1.4 Update bootstrap backend examples and notes if needed so the state bucket and lock table remain unchanged.

## 2. GitHub Actions Workflow Changes

- [x] 2.1 Remove automatic bootstrap `tofu apply` on push to `main` from the AWS infrastructure workflow.
- [x] 2.2 Keep or add bootstrap PR validation for `tofu fmt`, `tofu init -backend=false`, and `tofu validate`.
- [x] 2.3 Define the AWS workload root convention: folder-based deployable roots under `infrastructure/aws/*`, excluding manually controlled roots such as `bootstrap/` and `identity/`.
- [x] 2.4 Add changed-root detection for AWS pull requests so CI validates only affected AWS roots plus any required always-validate roots.
- [x] 2.5 Add changed-root detection for pushes to `main` so CI applies only affected deployable AWS workload roots.
- [x] 2.6 Configure the workflow to exclude manual roots (`bootstrap/`, `identity/`) from automatic applies while still validating them on pull requests.
- [x] 2.7 Configure per-root backend initialization using a deterministic state key convention such as `aws/<root-name>/global.tfstate`.
- [x] 2.8 Ensure workflow-only changes run safe validation and do not blindly apply every AWS workload root unless explicitly intended.
- [x] 2.9 Document how a new AWS workload folder opts into CI validation and apply behavior.

## 3. AWS Main Deployment Identity

- [x] 3.1 Create a dedicated manually applied identity root, such as `infrastructure/aws/identity`, for GitHub OIDC and AWS main deploy role resources.
- [x] 3.2 Create the AWS main OIDC trust relationship for `repo:chris-jelly/jellylabs-dsc:ref:refs/heads/main` and audience `sts.amazonaws.com`.
- [x] 3.3 Add remote-state permissions for the main state key and DynamoDB lock table.
- [x] 3.4 Add AWS Budgets permissions required for monthly budget and notification resources.
- [x] 3.5 Add SNS permissions required for uptime topics, subscriptions, attributes, and publishing.
- [x] 3.6 Add DynamoDB permissions required for the heartbeat registry table.
- [x] 3.7 Add Lambda permissions required for heartbeat receiver and checker functions, including code updates and function URL or invocation permissions if selected.
- [x] 3.8 Add EventBridge rules or Scheduler permissions required for scheduled checker invocation and targets.
- [x] 3.9 Add CloudWatch Logs permissions required for Lambda log groups and retention.
- [x] 3.10 Add manually managed heartbeat execution roles and constrained `iam:PassRole` permissions for Lambda, EventBridge, and Scheduler.
- [x] 3.11 Split S3 state bucket location and prefix-scoped list permissions so backend initialization can read the bucket location.
- [x] 3.12 Permit the AWS main deployment role to access per-root workload state keys such as `aws/<root-name>/global.tfstate`.

## 4. Pending Guardrails and Heartbeat Change Alignment

- [x] 4.1 Update `add-aws-guardrails-and-homelab-heartbeat` proposal and design text to depend on AWS main OIDC rather than bootstrap OIDC.
- [x] 4.2 Update guardrails and heartbeat tasks to verify the AWS main deploy role permissions before applying workload resources.
- [x] 4.3 Update guardrails and heartbeat resources to target an AWS workload root folder and its own remote-state key instead of the parent `infrastructure/aws` directory.
- [x] 4.4 Record any additional service permissions discovered during implementation as reviewed main deploy role expansions.

## 5. Migration and Repository Configuration

- [x] 5.1 Document the manual apply order: bootstrap cleanup, identity root apply, and then AWS main GitHub applies.
- [x] 5.2 Document required GitHub repository variables, including `AWS_MAIN_ROLE_ARN`, `AWS_STATE_BUCKET`, and `AWS_STATE_LOCK_TABLE`.
- [x] 5.3 Remove or deprecate `AWS_BOOTSTRAP_ROLE_ARN` usage from workflows and docs.
- [x] 5.4 Apply bootstrap or identity changes locally with operator admin credentials after review.

## 6. Validation

- [x] 6.1 Run OpenTofu formatting and validation for the bootstrap root.
- [x] 6.2 Run OpenTofu formatting and validation for representative changed AWS workload roots through the new folder-based CI path.
- [x] 6.3 Run a bootstrap plan with operator credentials and confirm only intended OIDC/IAM cleanup and retained state resources are present.
- [x] 6.4 Run an AWS workload root plan or apply through GitHub OIDC after the main role exists.
- [x] 6.5 Run OpenSpec validation for `rework-aws-oidc-deployment`.
