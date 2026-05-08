# AWS Infrastructure

This tree is intentionally minimal in the first wave.

## Included

- Provider entry point
- Region variable
- Bootstrap path for AWS state and CI identity resources

## Local AWS authentication

Run the AWS login bridge before planning or applying AWS stacks locally:

```bash
mise run aws-tofu-login
```

The task uses two local AWS profiles:

- `tofu-login` is the AWS CLI login profile. `aws login --profile tofu-login` opens the browser login and stores the AWS CLI session.
- `tofu-local` is the OpenTofu profile. It uses `credential_process` to export credentials from `tofu-login` in the format OpenTofu's AWS SDK can read.

Keep `AWS_PROFILE=tofu-local` for local OpenTofu commands. If you need to refresh the browser login manually, run `aws login --profile tofu-login`; do not run plain `aws login` while `AWS_PROFILE=tofu-local` is active.

## Excluded

- Default VPC management
- Intentional networking baseline
- Workload resources beyond bootstrap preparation
