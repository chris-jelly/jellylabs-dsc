## Context

The AWS infrastructure workflow currently uses a dynamic matrix to validate or apply changed direct child roots under `infrastructure/aws/`. The strategy fits the repository model: AWS roots are independent workloads, while `bootstrap/` and `identity/` remain manually controlled foundation roots.

The weak points are where policy lives and what PRs show. Root discovery, manual-root filtering, and workflow-change behavior live in inline Python inside the workflow. Pull requests run `fmt` and `validate`, but they do not produce an execution plan. The workflow also pins older action major versions and does not declare a GitHub deployment environment for applies.

Shared AWS modules are expected later. A shared module change can affect every workload root even when no root directory changes, so root detection needs an explicit rule for shared paths.

## Goals / Non-Goals

**Goals:**

- Keep the changed-root matrix strategy for independent AWS workload roots.
- Move root detection policy into a checked-in script that can be reviewed and tested outside workflow YAML.
- Add PR planning for deployable AWS workload roots.
- Use a separate AWS plan role for pull request planning.
- Treat shared AWS module changes as affecting all deployable workload roots.
- Keep manual roots validated but never automatically planned for apply or applied by the workload workflow.
- Update workflow actions to current supported major versions after reviewing their migration notes.
- Gate apply jobs with the `aws-production` GitHub Environment so deployment approval is distinct from branch protection.

**Non-Goals:**

- Introduce Atlantis, Terragrunt, Spacelift, Scalr, env0, or another orchestration platform.
- Add dependency graph scheduling between AWS roots.
- Auto-apply `bootstrap/` or `identity/`.
- Add automated planning for `bootstrap/` or `identity` in the workload CI workflow.
- Make shared modules independently deployable.
- Replace the current S3/DynamoDB backend model.

## Decisions

### Keep dynamic root detection, but move policy out of YAML

The workflow will call a repository script to emit JSON arrays for validation, planning, and applying. This keeps the workflow small while preserving the useful matrix fan-out pattern.

Alternative considered: keep inline Python. This is simplest, but the inline script already contains deployment policy. Moving it to a script makes the policy easier to read, review, and test.

Alternative considered: use a generic changed-files action. This reduces custom code, but the repository still needs domain-specific rules for manual roots, deployable roots, workflow changes, and shared modules.

### Use explicit root categories

The detector will distinguish:

- manual roots: `bootstrap`, `identity`
- deployable workload roots: direct AWS child directories with OpenTofu files, excluding manual roots and non-root directories
- shared module paths: reserved paths such as `infrastructure/aws/modules/**`
- workflow/tooling paths: the AWS workflow and detector script

On pull requests, root-specific changes validate and plan only affected roots. Workflow or detector changes validate and plan all deployable workload roots, but do not touch manual roots unless the manual root files changed. Shared module changes validate and plan all deployable workload roots.

On pushes to `main`, root-specific changes apply only affected deployable roots. Shared module changes apply all deployable workload roots because each root may consume the changed module. Workflow or detector changes alone do not trigger applies. Manual roots are excluded from apply.

### Add PR plans with a separate plan role

Pull request planning will assume an AWS plan role exposed through a repository variable such as `AWS_PLAN_ROLE_ARN`. The role should be able to read remote state and inspect AWS resources needed by OpenTofu plans, but it should not be able to create, update, or delete workload resources.

Planning is not perfectly read-only in every provider scenario, so the role is "read-only-ish": it grants state access and AWS read/list/describe permissions needed for supported workloads, plus any narrowly scoped non-mutating permissions OpenTofu requires. Apply remains limited to the main deployment role.

Alternative considered: use the existing main deployment role for PR plans. This is easier, but it gives pull request jobs mutation-capable credentials.

Alternative considered: skip PR plans. This keeps PRs safer and simpler, but reviewers cannot see infrastructure effects before merge.

### Publish plan output in PR comments and job summaries

The plan job will publish a concise pull request comment for reviewers and a job summary for workflow diagnostics. The PR comment should summarize each planned root and avoid dumping unbounded plan output into the conversation. The job summary can include fuller per-root details and links to logs.

Alternative considered: job summary only. This keeps PRs quieter, but reviewers may miss infrastructure impact while reviewing code.

Alternative considered: full plan comments only. This maximizes visibility, but long comments become noisy and hard to review.

### Keep manual-root planning out of workload CI

The workload CI workflow will validate manual roots when their files change, but it will not plan or apply them. Manual roots control the AWS foundation and deployment identity, so they should not share the routine workload deployment path.

If plan visibility for `bootstrap` or `identity` becomes necessary, add a separate manual-root planning workflow with its own credentials and approval model. That future workflow should remain plan-only unless a later design explicitly changes the manual apply boundary.

Alternative considered: plan manual roots in the same PR workflow. This would improve review visibility, but it would mix control-plane review with routine workload CI and require broader credentials in the main infrastructure workflow.

### Use a GitHub Environment for applies

The apply job will reference the `aws-production` environment. Repository maintainers can configure that environment with required reviewers and branch restrictions. Future environments, such as `aws-staging`, can be added without renaming the production gate.

Branch protection controls whether code reaches `main`. The environment controls whether a deployment job may proceed after the workflow has started. These protections complement each other.

### Update action major versions deliberately

The workflow will update actions after checking migration notes:

- `actions/checkout`: current major is newer than `v4`; newer majors use newer Node runtimes and may require current runner versions.
- `opentofu/setup-opentofu`: current major is newer than `v1` and supports version pinning and wrapper configuration.
- `aws-actions/configure-aws-credentials`: current major is newer than `v4`; migration notes must be checked for input or runtime changes.

The workflow should continue pinning the OpenTofu CLI version explicitly.

## Risks / Trade-offs

- Plan role lacks needed read permission → PR plans fail. Mitigation: start from least privilege, add reviewed read permissions as workloads require them.
- Plan role accidentally gets mutation permissions → PR jobs become too powerful. Mitigation: keep plan permissions separate from apply permissions and review IAM diffs carefully.
- Shared module changes apply more roots than necessary → slower and potentially noisier applies. Mitigation: accept this conservative rule while roots are independent; add module-to-root dependency metadata only if the cost becomes real.
- GitHub Environment gate slows urgent applies → require deliberate approval only on apply, not on validation or planning.
- Action major upgrades introduce runtime changes → review release notes and test workflow behavior in PR before relying on the updated workflow.

## Migration Plan

1. Add the detector script and update the workflow to consume its outputs.
2. Add PR planning with the plan role variable and remote backend initialization.
3. Extend identity infrastructure to create or document the AWS plan role.
4. Update action major versions and verify runner compatibility.
5. Add the apply environment reference to the workflow.
6. Configure the GitHub `aws-production` environment with branch restrictions and, if desired, required reviewers.

Rollback is straightforward for workflow-only changes: revert the workflow and detector script. IAM changes for the plan role can remain unused or be removed in a follow-up change.

## Open Questions

- None.
