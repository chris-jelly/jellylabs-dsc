## ADDED Requirements

### Requirement: AWS bootstrap scope is limited to state and CI identity
The AWS bootstrap foundation SHALL include only the resources required for OpenTofu remote state and GitHub Actions OIDC authentication.

#### Scenario: Bootstrap excludes lab workloads
- **WHEN** an operator reviews the AWS bootstrap foundation scope
- **THEN** budget controls, EventBridge resources, queues, functions, databases, APIs, and application workloads are outside the change

### Requirement: Remote state backend is available for later AWS stacks
The AWS bootstrap foundation SHALL provide an S3 remote state backend in `ca-central-1` for AWS OpenTofu stacks.

#### Scenario: Later stacks can use remote state
- **WHEN** an AWS lab stack is created after bootstrap
- **THEN** it can be configured to store OpenTofu state in the bootstrap-managed remote backend

### Requirement: Remote state is protected against accidental loss
The AWS bootstrap foundation SHALL protect remote state with encryption and versioning.

#### Scenario: State object protection is configured
- **WHEN** the remote state backend is provisioned
- **THEN** state objects are encrypted at rest and previous state versions can be recovered

### Requirement: Remote state locking uses DynamoDB
The AWS bootstrap foundation SHALL provide a DynamoDB table for OpenTofu remote state locking.

#### Scenario: Concurrent state writes are locked
- **WHEN** multiple OpenTofu operations target the same AWS remote state
- **THEN** the DynamoDB lock table prevents concurrent state writes

### Requirement: GitHub Actions authenticates with OIDC
The AWS bootstrap foundation SHALL allow GitHub Actions from the intended repository to authenticate to AWS by assuming an IAM role through OpenID Connect.

#### Scenario: GitHub workflow receives temporary AWS credentials
- **WHEN** an authorized GitHub Actions workflow requests AWS access through OIDC
- **THEN** AWS issues temporary credentials for the configured deployment role without requiring static AWS access keys in GitHub secrets

### Requirement: OIDC trust is constrained to the intended repository path
The AWS bootstrap foundation SHALL constrain the OIDC trust relationship to the intended GitHub repository and the `main` branch.

#### Scenario: Unauthorized repository cannot assume the role
- **WHEN** a workflow from another repository attempts to assume the bootstrap deployment role
- **THEN** AWS denies the request because the OIDC subject condition does not match

#### Scenario: Non-main branch cannot assume the apply role
- **WHEN** a workflow from a branch other than `main` attempts to assume the bootstrap deployment role
- **THEN** AWS denies the request because the OIDC subject condition does not match

### Requirement: AWS CI applies are scoped to AWS bootstrap folder changes
The AWS bootstrap foundation SHALL define GitHub Actions trigger expectations so AWS bootstrap OpenTofu applies run on `main` only when AWS bootstrap infrastructure paths change.

#### Scenario: Non-AWS changes do not trigger AWS apply
- **WHEN** a change is merged to `main` that modifies only Azure or other non-AWS infrastructure paths
- **THEN** the AWS OpenTofu apply workflow does not run

#### Scenario: Non-bootstrap AWS changes do not trigger bootstrap apply
- **WHEN** a change is merged to `main` that modifies AWS paths outside the bootstrap stack
- **THEN** the AWS bootstrap OpenTofu apply workflow does not run

#### Scenario: AWS changes trigger automatic apply
- **WHEN** a change is merged to `main` that modifies AWS bootstrap infrastructure paths
- **THEN** the AWS OpenTofu apply workflow runs automatically using the OIDC deployment role

### Requirement: CI role permissions are intentionally bounded
The AWS bootstrap foundation SHALL define the GitHub Actions deployment role with permissions that are intentionally scoped for bootstrap and future approved OpenTofu operations.

#### Scenario: Role permissions are reviewable before expansion
- **WHEN** a later AWS lab change requires additional AWS services
- **THEN** any new CI role permissions are reviewed as part of that later change rather than assumed by the bootstrap scope
