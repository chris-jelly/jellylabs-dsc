## MODIFIED Requirements

### Requirement: AWS bootstrap scope is limited to remote state
The AWS bootstrap foundation SHALL include only the resources required for OpenTofu remote state storage and state locking.

#### Scenario: Bootstrap excludes CI identity and lab workloads
- **WHEN** an operator reviews the AWS bootstrap foundation scope
- **THEN** GitHub OIDC providers, GitHub deployment roles, budget controls, EventBridge resources, queues, functions, databases, APIs, and application workloads are outside the bootstrap scope

## REMOVED Requirements

### Requirement: GitHub Actions authenticates with OIDC
**Reason**: OIDC authentication belongs to the normal AWS main deployment boundary, while bootstrap is manually applied as the root of trust.
**Migration**: Remove bootstrap-managed GitHub OIDC provider and role resources, then create the AWS main deployment identity under the new `aws-main-oidc-deployment` capability.

### Requirement: OIDC trust is constrained to the intended repository path
**Reason**: The bootstrap stack will no longer own an OIDC trust relationship.
**Migration**: Define repository and branch trust constraints on the AWS main deployment role instead.

### Requirement: AWS CI applies are scoped to AWS bootstrap folder changes
**Reason**: Bootstrap changes are sensitive and rare, and automatic bootstrap applies require either excessive permissions or a role that cannot update itself.
**Migration**: Keep bootstrap validation in CI and apply bootstrap changes manually with operator admin credentials or a later protected manual workflow.

### Requirement: CI role permissions are intentionally bounded
**Reason**: The bootstrap foundation will no longer define a GitHub Actions deployment role.
**Migration**: Move intentionally bounded CI deployment permissions to the AWS main deployment role and expand them through reviewed changes.
