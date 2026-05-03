# Bootstrap Conventions

## Remote State Strategy

- Each cloud keeps separate backend configuration.
- Bootstrap state is isolated from workload state.
- Workload stacks use distinct state objects rather than sharing one state file.
- Backend storage is dedicated to OpenTofu state and not reused by application workloads.
- Provider-specific backend details live in each cloud's bootstrap README.

## CI Authentication and Authorization

- CI uses short-lived federated cloud credentials when a workflow needs cloud access.
- Long-lived cloud credentials are not stored in repository secrets for routine plan or apply operations.
- Cloud deployment roles are scoped to the relevant repository path, branch, and stack.
- Bootstrap identity resources are treated carefully because they can control later CI access.

## CI Validation Expectations

- Shared validation runs formatting and static OpenTofu validation without backend or cloud login.
- Cloud-specific workflows may add authenticated plan or apply jobs where needed.
- Apply workflows are path-scoped so one cloud or stack does not deploy because another cloud changed.
- Bootstrap stacks and workload stacks apply separately to preserve state isolation.
- Branch protection and review happen before automatic `main` branch applies.
