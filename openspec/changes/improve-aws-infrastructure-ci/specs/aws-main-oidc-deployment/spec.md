## ADDED Requirements

### Requirement: AWS PR planning uses a separate plan role
The AWS main OIDC deployment SHALL provide or require a separate AWS role for pull request planning that is distinct from the main deployment role used for applies.

#### Scenario: Pull request plan uses plan role ARN
- **WHEN** the AWS workflow plans a deployable workload root for a pull request
- **THEN** it configures AWS credentials by assuming the plan role rather than the main deployment role

#### Scenario: Pull request plan role is constrained
- **WHEN** the AWS plan role is assumed through GitHub OIDC
- **THEN** AWS allows the role assumption only for the intended repository and pull request planning workflow context

### Requirement: AWS plan role avoids workload mutation permissions
The AWS plan role SHALL avoid permissions to create, update, or delete AWS workload resources while allowing the read and state access needed for OpenTofu planning.

#### Scenario: OpenTofu reads state during plan
- **WHEN** the AWS workflow runs `tofu plan` for a deployable workload root
- **THEN** the plan role can read the root's remote state and use the shared state lock table as required for planning

#### Scenario: OpenTofu inspects existing AWS resources
- **WHEN** the AWS provider refreshes state during planning
- **THEN** the plan role can perform the read, list, and describe operations required by supported AWS workload roots

#### Scenario: Plan role is used for mutation
- **WHEN** a workflow attempts to create, update, or delete workload resources using the plan role
- **THEN** AWS denies the mutation unless a narrowly reviewed exception has been added for planning behavior
