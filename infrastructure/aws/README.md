# AWS Infrastructure

This tree contains AWS lab infrastructure managed with OpenTofu.

## Included

- Folder-based AWS workload roots under this directory
- Bootstrap path for manually applied remote-state resources
- Identity path for manually applied GitHub OIDC and AWS main deploy role resources

## Local AWS authentication

Run the AWS login bridge before planning or applying AWS stacks locally:

```bash
mise run aws-tofu-login
```

The task uses two local AWS profiles:

- `tofu-login` is the AWS CLI login profile. `aws login --profile tofu-login` opens the browser login and stores the AWS CLI session.
- `tofu-local` is the OpenTofu profile. It uses `credential_process` to export credentials from `tofu-login` in the format OpenTofu's AWS SDK can read.

Keep `AWS_PROFILE=tofu-local` for local OpenTofu commands. If you need to refresh the browser login manually, run `aws login --profile tofu-login`; do not run plain `aws login` while `AWS_PROFILE=tofu-local` is active.

## Deployment model

1. Apply `bootstrap/` manually with operator admin credentials to create the S3 state bucket and DynamoDB lock table.
2. Apply `identity/` manually with operator admin credentials to create the GitHub OIDC provider and `jellylabs-tofu-main` role.
3. Store these GitHub repository variables:
   - `AWS_MAIN_ROLE_ARN`: IAM role ARN from the identity `main_role_arn` output.
   - `AWS_PLAN_ROLE_ARN`: IAM role ARN from the identity `plan_role_arn` output.
   - `AWS_STATE_BUCKET`: S3 bucket name from the bootstrap `state_bucket` output.
   - `AWS_STATE_LOCK_TABLE`: DynamoDB table name from the bootstrap `lock_table` output.
4. Configure the `aws-production` GitHub Environment for apply jobs. Restrict deployments to `main` and add required reviewers if production applies should wait for approval.
5. Let GitHub Actions plan changed deployable workload roots on pull requests and apply changed deployable workload roots on pushes to `main`.

## Workload root convention

Each direct child directory under `infrastructure/aws/` that contains OpenTofu files is treated as an AWS root. `bootstrap/` and `identity/` are manual roots: pull requests validate them, but GitHub Actions does not apply them.

Deployable workload roots use one remote-state key per folder:

```text
infrastructure/aws/guardrails        -> aws/guardrails/global.tfstate
infrastructure/aws/homelab-heartbeat -> aws/homelab-heartbeat/global.tfstate
```

To add a workload root:

1. Create `infrastructure/aws/<root-name>/`.
2. Add the root's `*.tf` files and, if useful for local work, `backend.tf.example` and `backend.hcl.example`.
3. Use the shared bootstrap bucket and lock table for remote state.
4. Open a pull request. CI validates changed AWS roots.
5. Review the PR plan comment for deployable workload roots.
6. Merge to `main`. CI applies only changed deployable roots through the `aws-production` environment; it skips `bootstrap/` and `identity/`.

Shared modules under `infrastructure/aws/modules/` are not deployable roots. Changes there validate and plan every deployable workload root on pull requests, and apply every deployable workload root on `main`.

Manual roots remain outside workload CI planning and apply. If `bootstrap/` or `identity/` plan visibility is needed later, add a separate plan-only workflow with its own credentials and approval model.

## Excluded

- Default VPC management
- Intentional networking baseline
- Bootstrap or identity auto-apply from GitHub Actions
