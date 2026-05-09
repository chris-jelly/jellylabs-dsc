# AWS Infrastructure

This tree contains AWS lab infrastructure managed with OpenTofu.

## Included

- Main AWS lab stack at this root
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
   - `AWS_STATE_BUCKET`: S3 bucket name from the bootstrap `state_bucket` output.
   - `AWS_STATE_LOCK_TABLE`: DynamoDB table name from the bootstrap `lock_table` output.
4. Let GitHub Actions apply the main AWS stack on pushes to `main` using the `aws/main/global.tfstate` state key.

## Excluded

- Default VPC management
- Intentional networking baseline
- Bootstrap or identity auto-apply from GitHub Actions
