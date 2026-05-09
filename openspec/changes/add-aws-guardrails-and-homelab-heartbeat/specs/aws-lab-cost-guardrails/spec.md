## ADDED Requirements

### Requirement: AWS lab monthly budget is defined
The AWS lab SHALL define a monthly cost budget with a budget limit of 5 USD.

#### Scenario: Monthly budget exists
- **WHEN** an operator reviews the AWS lab cost guardrails
- **THEN** a monthly AWS cost budget exists with a 5 USD limit

### Requirement: Budget alerts use native email notifications
The AWS lab budget SHALL notify configured email subscribers through AWS Budgets notifications without requiring SMS delivery.

#### Scenario: Budget threshold sends email notification
- **WHEN** AWS Budgets detects that configured actual or forecasted spend thresholds are crossed
- **THEN** AWS Budgets sends notifications to the configured email subscribers

#### Scenario: Budget alerts do not use SMS
- **WHEN** budget notifications are configured
- **THEN** SMS subscriptions are not required for budget alerting

### Requirement: Budget thresholds warn before and at the limit
The AWS lab budget SHALL include threshold notifications before the 5 USD limit is reached and when the budget is projected or expected to exceed the limit.

#### Scenario: Early warning thresholds are configured
- **WHEN** the monthly budget is configured
- **THEN** it includes actual-spend notifications below the budget limit

#### Scenario: Limit threshold is configured
- **WHEN** the monthly budget is configured
- **THEN** it includes a notification at the budget limit

#### Scenario: Forecasted threshold is configured
- **WHEN** projected monthly spend is expected to exceed the budget limit
- **THEN** AWS Budgets sends a forecasted-spend notification

### Requirement: AWS lab resources are tagged consistently
AWS lab resources managed by this change SHALL use consistent tags for lab ownership, environment, and cost visibility where the AWS service supports tagging.

#### Scenario: Taggable resources include lab tags
- **WHEN** a taggable AWS resource is created for this lab
- **THEN** it includes tags identifying the lab, environment, and ownership context

### Requirement: Cost guardrails avoid known high-cost services
The AWS lab SHALL avoid services and patterns known to create recurring baseline cost when they are not required for the lab goal.

#### Scenario: Near-free service choices are reviewed
- **WHEN** the lab infrastructure is designed or reviewed
- **THEN** it avoids NAT Gateway, continuously running cloud compute, load balancers, RDS, EKS, OpenSearch, VPC endpoints, Route 53 hosted zones, and unattached Elastic IPs unless explicitly justified by a later change
