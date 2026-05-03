## Context

The repository is moving toward AWS lab infrastructure managed with OpenTofu. Before any lab resources are added, the AWS side needs two bootstrap primitives: a remote state backend and a CI identity path. These primitives are foundational because later stacks need shared state storage and a safe way for GitHub Actions to run plans and applies.

This change keeps the bootstrap narrow. It does not create budget alerts, EventBridge rules, queues, Lambda functions, or other lab resources. CI workflow triggers should be path-scoped to AWS infrastructure folders so future Azure or other cloud changes can add their own deployment workflows independently.

## Goals / Non-Goals

**Goals:**
- Define an AWS bootstrap stack that creates the OpenTofu remote state backend.
- Define a GitHub Actions OIDC trust relationship for this repository.
- Create an IAM role that GitHub Actions can assume with short-lived AWS credentials.
- Keep the bootstrap layer stable and reusable for later AWS lab changes.

**Non-Goals:**
- Do not create AWS budget, alerting, or policy-control resources in this change.
- Do not create EventBridge, SQS, SNS, Lambda, API Gateway, DynamoDB, or static-site lab resources.
- Do not deploy application code.
- Do not introduce long-lived AWS access keys in GitHub repository secrets.

## Decisions

### Use a dedicated bootstrap stack

The bootstrap stack will contain only remote state infrastructure and GitHub OIDC deployment identity. Keeping it separate avoids coupling long-lived foundation resources to experimental lab stacks.

Alternative considered: put remote state, OIDC, budgets, and EventBridge into one foundation stack. That would be faster initially but would blur the boundary between bootstrap resources and disposable lab resources.

### Use S3 and DynamoDB for OpenTofu remote state

The bootstrap stack will provide an S3 bucket for remote state in `ca-central-1`. The bucket should use encryption and versioning so state is protected and recoverable. State locking will use a DynamoDB lock table.

Alternative considered: keep local state for early experiments. Local state is simpler but makes CI/CD deployment and team-safe workflows harder.

Alternative considered: use S3-native OpenTofu lock files. That would reduce resource count, but DynamoDB locking is the more established pattern and keeps lock state explicit.

### Use GitHub Actions OIDC instead of static AWS keys

GitHub Actions will authenticate to AWS through OIDC and assume an IAM role. This avoids storing long-lived AWS access keys in GitHub secrets and allows AWS trust conditions to constrain which repository, branch, or environment can assume the role.

Alternative considered: store an IAM user's access key in GitHub secrets. That is easier to wire up but increases credential-rotation and leakage risk.

### Trust the main branch for automatic applies

The AWS OIDC trust policy will allow the deployment role to be assumed from the intended repository's `main` branch. This supports automatic OpenTofu applies after changes merge to `main`.

Alternative considered: trust a protected GitHub environment. That provides an approval gate and deployment environment controls, but the lab currently favors automatic applies on `main`.

### Scope AWS bootstrap workflows to bootstrap path changes

The AWS bootstrap GitHub Actions workflow should run only when the AWS bootstrap path changes. This prevents bootstrap applies when a change touches Azure, other future cloud folders, or later AWS workload paths.

Alternative considered: run infrastructure workflows on every AWS path change. That is simpler but risks unnecessary or confusing bootstrap applies when later AWS environment stacks change.

### Scope the deploy role to bootstrap and future lab needs deliberately

The role should start with the permissions needed to manage the bootstrap-adjacent OpenTofu workflow and expand only when later changes define new managed resources. Permissions should be reviewed as part of each new AWS lab change.

Alternative considered: grant broad administrator access to the CI role for convenience. That makes experimentation easier but weakens the value of the lab as least-privilege practice.

## Risks / Trade-offs

- Bootstrap chicken-and-egg problem → Run the bootstrap stack locally with human AWS credentials once, then let GitHub Actions use the OIDC role for later workflows.
- Remote state bucket deletion risk → Enable versioning and avoid making the bucket easy to destroy during normal lab cleanup.
- Overly broad CI role permissions → Start narrow and require later changes to justify added permissions.
- Branch or repository trust misconfiguration → Restrict OIDC trust conditions to the intended repository and `main` branch.
- Cross-cloud or cross-stack workflow collisions → Use GitHub Actions path filters so the AWS bootstrap workflow triggers only for AWS bootstrap changes.

## Migration Plan

1. Apply the bootstrap stack locally using existing AWS credentials.
2. Configure later OpenTofu stacks to use the remote state backend created by bootstrap.
3. Add GitHub Actions workflows that run offline validation for AWS bootstrap pull requests and automatically run `tofu apply` on `main` when AWS bootstrap paths change.
4. Roll back by disabling or removing the GitHub OIDC role trust if CI access must be revoked.

## Open Questions

- None.
