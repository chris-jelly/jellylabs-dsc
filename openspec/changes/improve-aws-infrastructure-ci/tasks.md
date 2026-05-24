## 1. Detection Tooling

- [x] 1.1 Add a checked-in AWS root detection script that emits JSON outputs for validation, planning, and apply matrices.
- [x] 1.2 Encode manual roots, deployable roots, shared module paths, and workflow/tooling paths in the detector.
- [x] 1.3 Treat shared AWS module changes as affecting all deployable workload roots.
- [x] 1.4 Add detector tests or lightweight fixture checks for root changes, manual-root changes, workflow changes, shared-module changes, and workflow-only pushes to `main`.

## 2. Workflow Updates

- [x] 2.1 Update `.github/workflows/aws-infrastructure.yml` to call the detector script instead of inline Python.
- [x] 2.2 Add a pull request plan job for affected deployable AWS workload roots.
- [x] 2.3 Ensure PR validation covers affected manual roots only when manual root files change, while PR planning targets deployable workload roots and excludes manual roots.
- [x] 2.4 Keep push-to-main apply limited to affected deployable workload roots.
- [x] 2.5 Ensure workflow-only or detector-only pushes to `main` do not trigger automatic applies.
- [x] 2.6 Publish PR plan results as a concise pull request comment and in the job summary.
- [x] 2.7 Add the `aws-production` GitHub Environment reference to the apply job.
- [x] 2.8 Add concurrency controls for AWS applies if needed to avoid overlapping runs against the same root state.

## 3. AWS Identity and Repository Configuration

- [x] 3.1 Add or document an AWS plan role separate from the main deployment role.
- [x] 3.2 Constrain the plan role trust policy to the intended GitHub repository and PR planning context.
- [x] 3.3 Grant the plan role remote-state read and lock-table access needed for planning.
- [x] 3.4 Grant the plan role read/list/describe permissions required by supported AWS workload roots.
- [x] 3.5 Document the required GitHub repository variable, such as `AWS_PLAN_ROLE_ARN`.
- [x] 3.6 Document the required `aws-production` GitHub Environment configuration for AWS applies.
- [x] 3.7 Document that manual-root planning remains outside the workload CI workflow and should use a separate future workflow if needed.

## 4. Action Version Maintenance

- [x] 4.1 Review migration notes for `actions/checkout`, `opentofu/setup-opentofu`, and `aws-actions/configure-aws-credentials`.
- [x] 4.2 Update workflow action major versions where compatible with GitHub-hosted runners.
- [x] 4.3 Keep the OpenTofu CLI version pinned explicitly.

## 5. Validation

- [x] 5.1 Run detector checks locally against representative changed-file inputs.
- [x] 5.2 Run OpenSpec validation for the change.
- [x] 5.3 Verify the workflow syntax is valid.
- [x] 5.4 Verify detector behavior locally for a deployable root change, a manual root change, a shared module change, and a workflow/detector change.
- [x] 5.5 Verify detector behavior locally for main apply root selection, including manual-root exclusion and workflow-only changes.
- [x] 5.6 Fully deploy `add-aws-guardrails-and-homelab-heartbeat` so the repository has deployable AWS workload roots for live CI/CD validation.
- [x] 5.7 Verify a live PR workflow run for the guardrails/heartbeat workload roots creates plans, PR comments, and job summaries.
- [x] 5.8 Verify a live push-to-main workflow run for the guardrails/heartbeat workload roots uses the `aws-production` deployment environment gate before apply.

## 6. Manual Deployment and GitHub Setup

- [x] 6.1 Manually plan the changed `infrastructure/aws/identity` root with operator credentials.
- [x] 6.2 Review the identity plan for the new AWS plan role, plan role policy, OIDC trust, and outputs.
- [x] 6.3 Manually apply the changed `infrastructure/aws/identity` root after review.
- [x] 6.4 Store the new `plan_role_arn` output as the GitHub repository variable `AWS_PLAN_ROLE_ARN`.
- [x] 6.5 Create or update the GitHub `aws-production` environment.
- [x] 6.6 Restrict the `aws-production` environment to deployments from `main` and configure required reviewers if production applies should require approval.
