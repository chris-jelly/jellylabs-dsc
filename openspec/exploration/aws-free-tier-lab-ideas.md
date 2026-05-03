# AWS Free-Tier Lab Ideas

## Context

The AWS lab should favor services that provide useful Terraform/OpenTofu practice while staying inside free-tier or near-free usage. The bootstrap change is limited to remote state and GitHub Actions OIDC. These ideas remain outside that bootstrap scope.

## Candidate Lab Tracks

### Policy and Cost Controls

Practice account safety before deploying workloads.

- AWS Budgets for low-dollar spend alerts
- SNS topic for billing notifications
- Free Tier usage checks through AWS Billing and Cost Management
- Tagging conventions for lab resources
- Optional cost anomaly detection if the account supports it

Good OpenTofu practice:

- account-level resources
- notification wiring
- policy documents
- reusable guardrail module boundaries

### EventBridge Eventing Lab

Practice event-driven AWS architecture without running servers.

```text
EventBridge rule
      │
      ▼
SQS queue ──► Lambda worker ──► DynamoDB or logs
      │
      ▼
DLQ
```

Possible scenarios:

- scheduled lab heartbeat event
- toy order-processing event
- webhook event router
- daily report trigger

Good OpenTofu practice:

- event buses and rules
- target permissions
- queue and DLQ wiring
- IAM least privilege
- CloudWatch alarms and logs

### Serverless API Lab

Build a small API that avoids long-running compute.

```text
Client ──► API Gateway ──► Lambda ──► DynamoDB
```

Possible apps:

- todo API
- URL shortener
- lab inventory service
- feature flag service

Good OpenTofu practice:

- Lambda packaging
- API Gateway routes
- DynamoDB table design
- IAM execution roles
- environment-specific outputs

### Static Site or Lab Portal

Host simple lab documentation or a static UI.

```text
Browser ──► CloudFront ──► S3
```

Good OpenTofu practice:

- private S3 origins
- CloudFront origin access control
- cache behavior
- TLS with ACM if a domain is added later

Cost note: Route 53 hosted zones are not free, so use the CloudFront domain unless a small monthly hosted-zone cost is acceptable.

### IAM and CI/CD Practice

Extend the bootstrap OIDC role into a controlled deployment workflow.

```text
Pull request ──► tofu fmt / validate / plan
main branch  ──► tofu apply
manual run   ──► optional controlled operations
```

Good OpenTofu practice:

- trust policies
- GitHub environment protection
- least-privilege deploy roles
- plan/apply separation
- reusable workflow inputs

## Services to Prefer

| Service | Why it fits |
| --- | --- |
| IAM | Free and central to real AWS work |
| Lambda | Always-free allowance and no idle servers |
| DynamoDB | Always-free allowance and simple serverless storage |
| SQS | Always-free request allowance and strong eventing practice |
| SNS | Useful for alerts and fanout |
| EventBridge | Good architecture practice with low lab traffic |
| S3 | Cheap for state, static assets, and small objects |
| CloudFront | Useful CDN practice with free-tier-friendly usage |
| ACM | Public certificates are free |

## Services to Avoid for Near-Free Labs

- NAT Gateway
- EKS
- long-running ECS or Fargate services
- continuously running RDS instances
- Application or Network Load Balancers
- OpenSearch
- SageMaker
- VPC endpoints
- Route 53 hosted zones if the goal is absolute zero cost
- unattached Elastic IPs

## Likely Next Lab After Bootstrap

The strongest follow-up is a policy-control and EventBridge lab:

```text
Bootstrap foundation
   │
   ├── remote state
   └── GitHub OIDC role
          │
          ▼
Policy controls
   │
   ├── AWS Budget
   ├── SNS alert topic
   └── tagging conventions
          │
          ▼
EventBridge lab
   │
   ├── scheduled rule
   ├── SQS target + DLQ
   └── optional Lambda worker
```

This path keeps cost low while covering practical AWS and OpenTofu skills.
