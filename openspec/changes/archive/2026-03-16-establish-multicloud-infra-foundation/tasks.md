## 1. Repository Foundation

- [x] 1.1 Create the multi-cloud infrastructure directory structure for shared conventions plus separate Azure and AWS trees.
- [x] 1.2 Add OpenTofu project scaffolding, provider entry points, and repository documentation for the intended workflow.
- [x] 1.3 Document the initial adoption status vocabulary and repository ownership boundaries for authoritative, legacy, deferred, and unmanaged resources.

## 2. Bootstrap Conventions

- [x] 2.1 Define the remote state strategy for Azure and AWS, including backend naming and state isolation boundaries.
- [x] 2.2 Define CI authentication and authorization patterns for Azure and AWS, preferring short-lived federated access over static credentials.
- [x] 2.3 Add CI validation expectations for formatting, validation, planning, and gated apply behavior.

## 3. Azure Homelab Adoption

- [x] 3.1 Model the existing Azure homelab resource groups in OpenTofu without changing their current topology.
- [x] 3.2 Model the existing Azure Key Vault resources used for Kubernetes secret sync while keeping secret values out of initial management scope.
- [x] 3.3 Model the shared homelab backup storage account as authoritative infrastructure.
- [x] 3.4 Record the ActualBudget-specific backup storage account as a legacy resource and decide whether it is imported now or deferred with explicit documentation.

## 4. AWS First-Wave Baseline

- [x] 4.1 Create the AWS infrastructure tree and bootstrap placeholders needed for future intentional AWS resources.
- [x] 4.2 Mark the AWS default VPC as unmanaged or deferred in the adoption documentation and keep it out of first-wave authoritative management.

## 5. Verification and Follow-up Boundaries

- [x] 5.1 Validate that the planned first-wave resources and exclusions match the OpenSpec proposal, design, and specs.
- [x] 5.2 Identify follow-up changes for Azure resource-group consolidation, Key Vault rationalization, and migration away from the legacy ActualBudget backup account.
