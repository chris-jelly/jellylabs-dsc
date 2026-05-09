## Why

The AWS lab needs a safe bootstrap layer before any workload or eventing resources are deployed. Remote state and GitHub OIDC authentication establish the minimum foundation for repeatable OpenTofu operations without long-lived AWS credentials.

## What Changes

- Add an AWS bootstrap stack dedicated to OpenTofu remote state storage.
- Add a GitHub Actions OIDC trust path that allows this repository to assume a constrained AWS deployment role.
- Keep policy controls, budgets, alerts, EventBridge, and workload labs out of this bootstrap scope.
- Document the bootstrap boundary so later lab changes can depend on it instead of re-solving state and CI authentication.

## Capabilities

### New Capabilities
- `aws-bootstrap-foundation`: Defines the AWS remote state backend and GitHub OIDC deployment role required before AWS lab resources are managed by OpenTofu.

### Modified Capabilities
- None.

## Impact

- Adds OpenSpec artifacts for the AWS bootstrap foundation.
- Defines infrastructure expectations for an AWS S3-based remote state backend and a GitHub Actions OIDC IAM role.
- Does not implement application workloads, EventBridge resources, budgets, alerts, or cost controls in this change.
