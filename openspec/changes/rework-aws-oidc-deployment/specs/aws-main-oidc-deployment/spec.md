## ADDED Requirements

### Requirement: AWS main deployment uses GitHub OIDC
The AWS main deployment SHALL allow GitHub Actions to assume an AWS IAM role through OpenID Connect without storing long-lived AWS credentials in GitHub secrets.

#### Scenario: Main workflow receives temporary AWS credentials
- **WHEN** an authorized AWS main GitHub Actions workflow requests AWS credentials
- **THEN** AWS issues temporary credentials for the main deployment role through OIDC

### Requirement: AWS main OIDC trust is constrained
The AWS main deployment role SHALL constrain OIDC trust to the intended GitHub repository and the `main` branch.

#### Scenario: Main branch can assume the role
- **WHEN** a workflow from the intended repository's `main` branch requests the main deployment role
- **THEN** AWS allows the role assumption when the token audience is `sts.amazonaws.com`

#### Scenario: Unauthorized source cannot assume the role
- **WHEN** a workflow from another repository or non-main branch requests the main deployment role
- **THEN** AWS denies the role assumption because the OIDC subject condition does not match

### Requirement: AWS workload deployments use separate remote state
Each deployable AWS workload root SHALL use the bootstrap-managed remote backend with a root-specific state key separate from the bootstrap and identity stacks.

#### Scenario: Workload root initializes remote state
- **WHEN** the AWS workflow runs `tofu init` for a deployable workload root
- **THEN** it uses the bootstrap state bucket and lock table with a root-specific state key such as `aws/<root-name>/global.tfstate`

### Requirement: AWS workload workflow uses the main deploy role
The AWS GitHub Actions workflow SHALL assume the main deployment role through a repository variable such as `AWS_MAIN_ROLE_ARN` when applying deployable workload roots.

#### Scenario: Workload apply uses main role ARN
- **WHEN** the AWS workflow applies a deployable workload root on `main`
- **THEN** it configures AWS credentials by assuming the main deployment role rather than a bootstrap deployment role

### Requirement: AWS main deploy role can manage guardrails and heartbeat resources
The AWS main deployment role SHALL include the initial permissions required to manage the resources in `add-aws-guardrails-and-homelab-heartbeat`.

#### Scenario: Cost guardrails can be managed
- **WHEN** OpenTofu applies AWS lab cost guardrails
- **THEN** the main deployment role can manage AWS Budgets budget resources and budget notifications required by the cost guardrails

#### Scenario: Heartbeat alerting resources can be managed
- **WHEN** OpenTofu applies homelab heartbeat alerting resources
- **THEN** the main deployment role can manage SNS topics and subscriptions, DynamoDB heartbeat tables, Lambda functions, EventBridge rules or schedules, EventBridge targets, and CloudWatch Log Groups required by heartbeat alerting

#### Scenario: Heartbeat execution roles are pre-created
- **WHEN** OpenTofu applies heartbeat Lambda or EventBridge resources
- **THEN** the required execution roles are supplied by the manually applied identity root rather than created by the main deployment role

#### Scenario: Service roles can be passed only where needed
- **WHEN** OpenTofu configures Lambda functions or EventBridge targets that require execution roles
- **THEN** the main deployment role can pass only approved lab roles to the required AWS services

### Requirement: AWS main deploy permissions are reviewable before expansion
The AWS main deployment role SHALL expand permissions only through reviewed infrastructure changes as new AWS lab resource types are added.

#### Scenario: New service requires policy expansion
- **WHEN** a later AWS lab change requires a new AWS service not covered by the main deployment role
- **THEN** the required role policy expansion is reviewed as part of that change before workload resources are applied

### Requirement: Bootstrap auto-apply is not required for AWS main CD
The AWS main deployment SHALL not depend on automatic GitHub applies of the bootstrap stack.

#### Scenario: Bootstrap remains manually controlled
- **WHEN** the AWS main workflow applies normal lab resources
- **THEN** it uses an existing main deployment role created through the controlled bootstrap or admin path
