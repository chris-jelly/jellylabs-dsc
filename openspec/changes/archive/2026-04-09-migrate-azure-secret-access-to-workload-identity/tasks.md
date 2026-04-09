## 1. Add Key Vault workload identity and secret residency changes

- [x] 1.1 Add Terraform resources for the ESO Key Vault user-assigned managed identity and federated credential in `infrastructure/azure/homelab/` using the existing Arc OIDC issuer and subject `system:serviceaccount:external-secrets:azure-kv-store-reader`.
- [x] 1.2 Grant the ESO identity `Key Vault Secrets User` on `kv-jellyhomelabprod` and expose the ESO client and principal ID outputs needed by homelab.
- [x] 1.3 Manually copy `app--salesforce-consumer-key--prod` and `app--salesforce-private-key--prod` into `kv-jellyhomelabprod` while preserving the existing secret names.

## 2. Add ActualBudget backup workload identity resources

- [x] 2.1 Add Terraform resources for the ActualBudget user-assigned managed identity and federated credential for subject `system:serviceaccount:actualbudget:actualbudget-backup`.
- [x] 2.2 Add the private `actualbudget` blob container in `sthomelabbackups` and grant container-scoped `Storage Blob Data Contributor` to the ActualBudget identity.
- [x] 2.3 Expose the ActualBudget client ID, principal ID, container name, container resource ID, and destination URL outputs needed by homelab.

## 3. Prepare cutover and retirement sequencing

- [x] 3.1 Update stack documentation and handoff notes so homelab knows the expected ESO and ActualBudget service-account subjects, output values, and validation gates.
- [x] 3.2 Apply the Azure changes and capture the outputs needed for homelab-side workload identity cutover and backup configuration.
- [x] 3.3 Wait for homelab validation that `azure-kv-store` works with `WorkloadIdentity` and `serviceAccountRef`, Airflow renders `salesforce-conn` from `kv-jellyhomelabprod`, and an ActualBudget manual backup succeeds.

## 4. Retire legacy Azure resources after validation

- [x] 4.1 Remove the legacy `azure-creds` app registration / Service Principal path after the workload identity cutover is confirmed.
- [x] 4.2 Remove `kv-work-integrations` and `rg-work-integrations` from the Azure homelab stack after all validation gates pass and confirm no non-homelab consumers remain.
- [x] 4.3 Run formatting and validation for `infrastructure/azure/homelab/` and confirm the remaining steady-state topology matches the new specs.
