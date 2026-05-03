# Bootstrap Conventions

## Remote State Strategy

### Azure
- Azure state lives in a dedicated bootstrap storage account, not in an application-facing storage account.
- Recommended naming pattern: `sttfstate<environment>` with a `tfstate` container.
- State files are isolated by cloud, environment, and stack path, for example:
  - `azure/bootstrap/global.tfstate`
  - `azure/homelab/platform.tfstate`

### AWS
- AWS state uses a dedicated S3 bucket plus a DynamoDB lock table.
- Recommended naming pattern: `jellylabs-tofu-state-<account-id>-<region>`.
- State files are isolated by cloud, environment, and stack path, for example:
  - `aws/bootstrap/global.tfstate`
  - `aws/environments/homelab/platform.tfstate`

### Isolation Boundaries
- Each cloud keeps separate backend configuration.
- Bootstrap state is isolated from workload state.
- Production-grade future environments should receive distinct state objects rather than workspaces sharing one object.

## CI Authentication and Authorization

The current validation workflow does not yet authenticate to Azure or AWS. It only runs formatting and validation checks that do not require backend or cloud login.

### Intended Azure Model
- Future CI plan or apply workflows should use GitHub Actions OpenID Connect federation into a dedicated Entra application or managed identity path.
- CI should receive least-privilege roles scoped to the target subscription or resource group set.
- Static client secrets should not be stored in the repository.

### Intended AWS Model
- Future CI plan or apply workflows should assume an IAM role through GitHub Actions OIDC.
- The role trust policy should restrict access to the repository and `main` branch.
- Long-lived AWS access keys should not be used for routine plan or apply operations.
- The bootstrap CI role should not mutate its own IAM role, policy, or OIDC provider; those remain local bootstrap responsibilities.

## CI Validation Expectations

- The shared infrastructure validation workflow runs on qualifying pull requests, not push events.
- It runs `tofu fmt -check -recursive`, `tofu init -backend=false`, and `tofu validate` for the Azure and AWS roots.
- Non-destructive `tofu plan` automation for affected stacks is intended, but it is not fully wired yet.
- Bootstrap stacks and workload stacks are applied separately to preserve state isolation.
- AWS bootstrap applies are path-scoped to `infrastructure/aws/bootstrap/**` so other cloud folders can add separate deployment workflows.
- AWS applies run automatically on `main` after branch protections and review happen before merge.
