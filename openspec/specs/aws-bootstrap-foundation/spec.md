## Purpose

Define the AWS bootstrap foundation as the manually applied remote-state boundary for AWS OpenTofu work.

## Requirements

### Requirement: AWS bootstrap scope is limited to remote state
The AWS bootstrap foundation SHALL include only the resources required for OpenTofu remote state storage and state locking.

#### Scenario: Bootstrap excludes CI identity and lab workloads
- **WHEN** an operator reviews the AWS bootstrap foundation scope
- **THEN** GitHub OIDC providers, GitHub deployment roles, budget controls, EventBridge resources, queues, functions, databases, APIs, and application workloads are outside the bootstrap scope

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
