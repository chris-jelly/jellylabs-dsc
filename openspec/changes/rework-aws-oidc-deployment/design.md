## Context

The AWS bootstrap stack currently creates both the remote-state backend and the GitHub Actions OIDC deployment identity. The stack has already been applied locally with operator admin credentials. Its GitHub role is intentionally narrow, so it can use the state backend and read IAM resources, but it is not a practical path for changing its own trust policy or expanding AWS lab permissions.

The pending `add-aws-guardrails-and-homelab-heartbeat` change is the first normal AWS lab workload. It needs permissions for Budgets, SNS, DynamoDB, Lambda, EventBridge, CloudWatch Logs, and IAM execution roles. Those permissions belong to a normal AWS main deploy role, not to the bootstrap role.

## Goals / Non-Goals

**Goals:**

- Make bootstrap manual and narrow: S3 remote state and DynamoDB state locking only.
- Remove bootstrap OIDC resources and automatic bootstrap apply from GitHub Actions.
- Define a separate AWS main deploy role for normal OpenTofu CD.
- Constrain the main deploy role trust to this repository's `main` branch.
- Include the first permission set needed for the guardrails and heartbeat change.
- Keep future permission expansion reviewable as AWS lab state grows.

**Non-Goals:**

- Do not create a broad administrator CI role.
- Do not manage AWS Organizations, account-level guardrails, SCPs, or Control Tower.
- Do not solve multi-account or production environment deployment.
- Do not implement the guardrails and heartbeat resources in this change.
- Do not move bootstrap state or recreate the state bucket unless required by drift.

## Decisions

### Keep bootstrap manually applied

Bootstrap remains the root of trust and is applied with operator admin credentials when it changes. The bootstrap stack owns the remote state bucket and lock table only.

Alternatives considered:

- **GitHub auto-apply for bootstrap:** Convenient, but self-referential IAM creates a bad choice: either the role cannot update itself, or it becomes too powerful.
- **Delete bootstrap entirely:** Not appropriate because the remote-state backend and lock table still need an auditable OpenTofu definition.

### Move GitHub OIDC to the AWS main deployment boundary

The AWS main stack gets its own GitHub Actions deploy role. The workflow uses GitHub OIDC to assume that role on `main` and applies normal AWS lab infrastructure with a separate state key, such as `aws/main/global.tfstate`.

Alternatives considered:

- **Expand the bootstrap role forever:** Simpler at first, but it mixes foundation resources with workloads and grows into a broad CI role.
- **Create one role per service immediately:** Strong isolation, but more overhead than the lab needs before the workload surface grows.

### Manage deployment identity in a dedicated identity root

The AWS main deploy role and OIDC trust should live in a dedicated identity root, such as `infrastructure/aws/identity`, applied manually with operator admin credentials. This keeps bootstrap focused on state, keeps deployment identity separate from workload resources, and gives IAM changes a clear review path.

Alternatives considered:

- **Keep the main deploy role in bootstrap:** Works, but bootstrap would still own CI identity and blur the new boundary.
- **Keep the main deploy role in the main workload root:** Creates a self-management problem because the role used by GitHub would also manage its own permissions.

### Apply AWS main automatically on `main`

The AWS main workflow should apply automatically on pushes to `main` after PR validation succeeds and the main deploy role exists. This provides normal CD for lab resources while keeping bootstrap and identity changes manually controlled.

Alternatives considered:

- **Use only `workflow_dispatch` for main applies:** Safer while experimenting, but less useful as a CD pattern once OIDC and least-privilege permissions are in place.

### Start with one main deploy role, split later if blast radius grows

The first main role can manage the near-free AWS lab resources in the pending guardrails and heartbeat change. Later changes can split into stack-specific roles if resources become unrelated or more sensitive.

The initial policy should cover these resource families:

- Remote state access for the AWS main state key in the bootstrap S3 bucket and DynamoDB lock table.
- AWS Budgets resources and budget notifications.
- SNS topics, subscriptions, topic attributes, and publishing for uptime alerts.
- DynamoDB heartbeat registry table and item operations needed by OpenTofu-managed seed/configuration items if used.
- Lambda functions, function URLs or API Gateway integration if selected, permissions, aliases if needed, and code updates.
- EventBridge rules or Scheduler schedules, targets, and permissions used to invoke the checker.
- CloudWatch Log Groups and retention settings for Lambda logs.
- Constrained `iam:PassRole` for Lambda, EventBridge, and Scheduler execution roles created in the manually applied identity root.

The dangerous edge is IAM. The main deploy role should not create arbitrary IAM roles or policies in the first implementation. The manually applied identity root owns the initial heartbeat execution roles, and the main deploy role can only pass those approved roles to their matching services: Lambda for receiver/checker roles and Scheduler for the scheduler role.

### Defer IAM permission boundaries

Do not add IAM permission boundaries in the first AWS main OIDC implementation. Start with manually managed execution roles, constrained `iam:PassRole`, lab role naming or tagging conventions, and reviewed IAM changes. Add a permission boundary later if the main deploy role needs to create service-specific roles.

Alternatives considered:

- **Add a permission boundary now:** Stronger guardrail, but adds IAM complexity before the lab has enough roles to justify it.
- **Never use permission boundaries:** Simpler, but removes a useful future control if the deploy role starts creating many service roles.

### Update the pending guardrails and heartbeat change to depend on main OIDC

The pending change currently says it uses the existing bootstrap OIDC foundation. It should instead target the AWS main stack and assume `AWS_MAIN_ROLE_ARN`. Its implementation tasks should include verifying that the main deploy role policy covers the required services before applying workload resources.

Alternatives considered:

- **Let the pending change add permissions ad hoc:** Fast, but the deployment model remains unclear.
- **Block the pending change until this is implemented:** Safest. This change should land first because it defines the deployment boundary the pending workload will use.

## Risks / Trade-offs

- **Manual bootstrap changes require powerful human credentials** → Keep bootstrap rare and review changes carefully before local apply.
- **Main deploy role policy can sprawl** → Add permissions through reviewed OpenSpec changes and split roles when unrelated stacks appear.
- **Constrained IAM can break applies** → Start with named lab role patterns and document how to expand permissions intentionally.
- **Removing bootstrap OIDC may delete an existing role still referenced by GitHub variables** → Update or remove repository variables and workflow references during migration.
- **State separation can be misconfigured** → Use explicit backend keys for bootstrap and main, and validate workflow `tofu init` arguments.

## Migration Plan

1. Apply this change locally with operator admin credentials to remove bootstrap OIDC resources and leave state resources intact.
2. Create or update the AWS main deploy role and trust policy through the controlled local/admin path.
3. Configure GitHub repository variables for the AWS main workflow, including `AWS_MAIN_ROLE_ARN`, state bucket, and lock table values.
4. Replace the bootstrap auto-apply workflow with bootstrap validation and AWS main apply behavior.
5. Update the pending guardrails and heartbeat change to use the AWS main stack and its deploy role.
6. Run PR validation for bootstrap and main roots.
7. Apply the AWS main stack from GitHub after the main role exists.

Rollback: restore the previous bootstrap OIDC resources from git and apply locally with operator admin credentials, then restore the previous GitHub repository variables.

## Open Questions

- None.
