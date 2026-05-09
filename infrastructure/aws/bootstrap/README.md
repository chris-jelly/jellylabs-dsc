# AWS Bootstrap

This stack provisions the minimal AWS bootstrap required for later OpenTofu-managed AWS work. Apply it manually with operator admin credentials; it is the root of trust for remote state.

## Included

- S3 remote state bucket in `ca-central-1`
- DynamoDB lock table for OpenTofu state locking

## Notes

- Run this stack locally first with `tofu init -backend=false`, `tofu plan`, and `tofu apply`.
- After the first apply, copy `backend.tf.example` to `backend.tf` and copy `backend.hcl.example` to `backend.hcl`.
- Replace the example account ID in `backend.hcl`, then migrate the bootstrap stack to S3 state with `tofu init -migrate-state -backend-config=backend.hcl`.
- GitHub Actions validates bootstrap changes but does not apply this stack.
- Use the `state_bucket` and `lock_table` outputs as repository variables for non-bootstrap workflows:
  - `AWS_STATE_BUCKET`: S3 bucket name from the `state_bucket` output.
  - `AWS_STATE_LOCK_TABLE`: DynamoDB table name from the `lock_table` output.
- The AWS main deployment role is defined outside bootstrap in the manually applied identity root.
- No CI identity, workloads, networking baseline, budgets, alerts, or app resources are included.
