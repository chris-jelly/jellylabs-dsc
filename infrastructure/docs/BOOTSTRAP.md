# Bootstrap Conventions

## Remote State Strategy

### Azure
- Azure state lives in a dedicated bootstrap storage account, not in an application-facing storage account.
- Recommended naming pattern: `sttfstate<environment>` with a `tfstate` container.
- State files are isolated by cloud, environment, and stack path, for example:
  - `azure/bootstrap/global.tfstate`
  - `azure/homelab/platform.tfstate`

### AWS
- AWS state uses a dedicated S3 bucket plus a lock table if locking is enabled separately.
- Recommended naming pattern: `jellylabs-tofu-state-<account-id>-<region>`.
- State files are isolated by cloud, environment, and stack path, for example:
  - `aws/bootstrap/global.tfstate`
  - `aws/environments/homelab/platform.tfstate`

### Isolation Boundaries
- Each cloud keeps separate backend configuration.
- Bootstrap state is isolated from workload state.
- Production-grade future environments should receive distinct state objects rather than workspaces sharing one object.

## CI Authentication and Authorization

### Azure
- CI uses GitHub Actions OpenID Connect federation into a dedicated Entra application or managed identity path.
- CI receives least-privilege roles scoped to the target subscription or resource group set.
- Static client secrets are not stored in the repository.

### AWS
- CI assumes an IAM role through GitHub Actions OIDC.
- The role trust policy restricts access to the repository, branch, and workflow context.
- Long-lived AWS access keys are not used for routine plan or apply operations.

## CI Validation Expectations

- Pull requests run `tofu fmt -check -recursive`, `tofu init`, `tofu validate`, and a non-destructive `tofu plan` for affected stacks.
- Apply is gated to protected branches plus environment approval.
- Bootstrap stacks and workload stacks are applied separately to preserve state isolation.
- Any apply workflow must use reviewed plans or equivalent branch protections rather than ad hoc local drift reconciliation.
