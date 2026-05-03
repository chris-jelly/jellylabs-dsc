## 1. Bootstrap Structure

- [x] 1.1 Create the AWS bootstrap OpenTofu directory structure separate from later lab stacks.
- [x] 1.2 Configure the AWS provider, required versions, variables, outputs, and naming/tagging inputs for the bootstrap stack.

## 2. Remote State Backend

- [x] 2.1 Add the S3 remote state bucket with server-side encryption enabled.
- [x] 2.2 Enable versioning on the remote state bucket.
- [x] 2.3 Add bucket public-access blocking and ownership controls appropriate for private state storage.
- [x] 2.4 Add the DynamoDB table used for OpenTofu state locking.
- [x] 2.5 Output the backend values needed by later AWS OpenTofu stacks, including the S3 bucket, region, state key, and DynamoDB lock table.

## 3. GitHub Actions OIDC Role

- [x] 3.1 Add the GitHub Actions OIDC provider for `token.actions.githubusercontent.com` if it is not already managed.
- [x] 3.2 Add an IAM role trusted by the intended GitHub repository's `main` branch.
- [x] 3.3 Add least-privilege IAM policies needed for bootstrap and future approved OpenTofu operations.
- [x] 3.4 Output the role ARN for GitHub Actions workflow configuration.

## 4. AWS GitHub Actions Workflow

- [x] 4.1 Add AWS workflow trigger filters so AWS bootstrap jobs run only for AWS bootstrap path changes.
- [x] 4.2 Add pull request validation for AWS bootstrap infrastructure changes.
- [x] 4.3 Add automatic `tofu apply` on `main` for AWS bootstrap infrastructure changes.

## 5. Validation

- [x] 5.1 Run OpenTofu formatting and validation for the bootstrap stack.
- [ ] 5.2 Run an OpenTofu plan for the bootstrap stack and confirm only remote state, DynamoDB locking, OIDC, and AWS workflow resources are included.
- [x] 5.3 Document the one-time local bootstrap apply and later AWS bootstrap path-scoped CI usage path.
