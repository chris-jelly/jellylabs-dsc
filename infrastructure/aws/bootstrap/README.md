# AWS Bootstrap

This stack provisions the minimal AWS bootstrap required for later OpenTofu-managed AWS work.

## Included

- S3 remote state bucket in `ca-central-1`
- DynamoDB lock table for OpenTofu state locking
- GitHub Actions OIDC provider and `main`-branch deployment role

## Notes

- Run this stack locally first with `tofu init -backend=false`, `tofu plan`, and `tofu apply`.
- After the first apply, copy `backend.tf.example` to `backend.tf` and copy `backend.hcl.example` to `backend.hcl`.
- Replace the example account ID in `backend.hcl`, then migrate the bootstrap stack to S3 state with `tofu init -migrate-state -backend-config=backend.hcl`.
- The committed GitHub workflow writes `backend.tf` at runtime so the repository remains local-first for the initial bootstrap.
- The AWS workflow reads these repository variables:
  - `AWS_BOOTSTRAP_ROLE_ARN`: IAM role ARN from the `role_arn` output.
  - `AWS_STATE_BUCKET`: S3 bucket name from the `state_bucket` output.
  - `AWS_STATE_LOCK_TABLE`: DynamoDB table name from the `lock_table` output.
- Pull requests run offline validation only because the OIDC trust is restricted to `main`.
- Pushes to `main` under `infrastructure/aws/bootstrap/**` run automatic `tofu apply` for this stack.
- CI can read IAM bootstrap resources for drift detection, but IAM mutations remain a local bootstrap responsibility.
- No workloads, networking baseline, budgets, alerts, or app resources are included.
