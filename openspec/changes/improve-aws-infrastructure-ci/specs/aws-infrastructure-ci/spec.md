## ADDED Requirements

### Requirement: AWS CI detects affected roots outside workflow YAML
The AWS infrastructure workflow SHALL use checked-in repository tooling, rather than inline workflow code, to determine which AWS roots are affected by a workflow run.

#### Scenario: Root-specific change is detected
- **WHEN** a change modifies files under a deployable AWS workload root
- **THEN** the detector emits that root for validation, planning, and, on `main`, apply

#### Scenario: Manual root change is detected
- **WHEN** a change modifies files under `infrastructure/aws/bootstrap` or `infrastructure/aws/identity`
- **THEN** the detector emits the manual root for pull request validation but not for automatic apply

#### Scenario: Workflow tooling changes in a pull request
- **WHEN** a pull request modifies the AWS workflow or root detector tooling without modifying manual root files
- **THEN** the detector emits all deployable AWS workload roots for validation and planning and emits no manual roots

#### Scenario: Workflow tooling changes on main
- **WHEN** a push to `main` modifies only the AWS workflow or root detector tooling
- **THEN** the detector emits no roots for automatic apply

### Requirement: AWS CI treats shared module changes as affecting deployable roots
The AWS infrastructure workflow SHALL treat changes under shared AWS module paths as affecting every deployable AWS workload root.

#### Scenario: Shared module changes in a pull request
- **WHEN** a pull request modifies a shared AWS module path
- **THEN** the workflow validates and plans every deployable AWS workload root

#### Scenario: Shared module changes on main
- **WHEN** a push to `main` modifies a shared AWS module path
- **THEN** the workflow applies every deployable AWS workload root and excludes manual roots

### Requirement: AWS CI validates pull requests before planning
The AWS infrastructure workflow SHALL run OpenTofu formatting and validation checks for affected AWS roots on pull requests before relying on plan output.

#### Scenario: Pull request changes a workload root
- **WHEN** a pull request modifies an affected AWS workload root
- **THEN** the workflow runs `tofu fmt -check`, backendless initialization, and `tofu validate` for that root

### Requirement: AWS CI plans deployable roots on pull requests
The AWS infrastructure workflow SHALL produce an OpenTofu plan for affected deployable AWS workload roots on pull requests.

#### Scenario: Pull request changes a deployable root
- **WHEN** a pull request modifies a deployable AWS workload root
- **THEN** the workflow initializes that root with the remote backend and runs `tofu plan` for review

#### Scenario: Pull request changes a manual root
- **WHEN** a pull request modifies `bootstrap` or `identity`
- **THEN** the workflow validates the manual root without treating it as an automatically deployable workload root

#### Scenario: Manual root planning is requested from workload CI
- **WHEN** the AWS workload workflow handles a change to `bootstrap` or `identity`
- **THEN** the workflow does not run `tofu plan` for the manual root

### Requirement: AWS CI publishes pull request plan output
The AWS infrastructure workflow SHALL publish pull request plan results in both a pull request comment and the workflow job summary.

#### Scenario: Pull request plan completes
- **WHEN** the workflow plans affected deployable AWS workload roots for a pull request
- **THEN** the workflow posts a concise pull request comment summarizing the plan result for each root

#### Scenario: Reviewer inspects workflow run
- **WHEN** a reviewer opens the workflow run summary for a pull request plan
- **THEN** the summary includes plan details for the affected deployable AWS workload roots

### Requirement: AWS CI applies only deployable roots on main
The AWS infrastructure workflow SHALL automatically apply affected deployable AWS workload roots only from pushes to `main`.

#### Scenario: Main receives deployable root change
- **WHEN** a push to `main` modifies a deployable AWS workload root
- **THEN** the workflow applies that root with the main deployment role

#### Scenario: Main receives manual root change
- **WHEN** a push to `main` modifies `bootstrap` or `identity`
- **THEN** the workflow does not automatically apply that manual root

### Requirement: AWS apply jobs use a deployment environment
The AWS infrastructure workflow SHALL associate automatic apply jobs with the `aws-production` GitHub deployment environment.

#### Scenario: Apply job starts
- **WHEN** the workflow is ready to apply an affected deployable AWS workload root
- **THEN** GitHub evaluates the configured `aws-production` deployment environment protection rules before the apply steps proceed

### Requirement: AWS CI uses maintained action majors
The AWS infrastructure workflow SHALL use maintained major versions of its GitHub Actions dependencies after their migration notes have been reviewed.

#### Scenario: Workflow installs dependencies
- **WHEN** the AWS infrastructure workflow runs
- **THEN** checkout, OpenTofu setup, and AWS credential actions use current supported major versions compatible with GitHub-hosted runners
