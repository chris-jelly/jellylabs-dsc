## Why

The AWS infrastructure workflow now encodes deployment policy inside inline Python, validates pull requests without showing a plan, and uses action versions that have newer supported major releases. As AWS workload roots grow and start sharing common modules, the CI/CD contract should be explicit, reviewable, and safe before `main` applies changes.

## What Changes

- Move AWS root detection out of `.github/workflows/aws-infrastructure.yml` and into a checked-in script.
- Add pull request planning for deployable AWS workload roots using a separate read-only-ish AWS plan role.
- Keep deployable roots independent while treating shared AWS module changes as affecting all deployable roots.
- Keep `bootstrap/` and `identity/` as manual roots that can be validated but are not automatically applied.
- Update GitHub Actions dependencies to current supported major versions after checking their migration notes.
- Add an explicit GitHub Environment gate for AWS apply jobs so deployment approval and branch restrictions are separate from merge protection.

## Capabilities

### New Capabilities
- `aws-infrastructure-ci`: Defines the AWS OpenTofu CI/CD behavior for root detection, validation, planning, applying, shared module changes, action maintenance, and deployment gating.

### Modified Capabilities
- `aws-main-oidc-deployment`: Adds PR planning through a separate plan role while keeping main-branch applies on the main deployment role.

## Impact

- `.github/workflows/aws-infrastructure.yml`
- New AWS root detection script under the repository tooling or scripts tree
- AWS identity/root configuration for a plan role and GitHub repository variable such as `AWS_PLAN_ROLE_ARN`
- GitHub repository environment configuration for AWS applies
- OpenTofu PR review workflow and branch-to-main deployment flow
