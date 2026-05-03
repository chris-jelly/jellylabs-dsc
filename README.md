# jellylabs-dsc

Infrastructure-as-code repository for Jellylabs cloud platforms. This repo uses OpenTofu to manage Azure and AWS foundation work, with OpenSpec used as the change-spec workflow for planning and tracking infrastructure changes.

## What this repo covers

- Multi-cloud infrastructure layout for Azure and AWS.
- Brownfield Azure homelab adoption, including shared backup infrastructure.
- Bootstrap conventions for remote state, CI authentication, and validation.
- OpenSpec change proposals and accepted specifications for infrastructure work.

## Current focus

The first wave of adoption is intentionally narrow:

- Azure homelab support resources are being brought under management.
- Azure remote state bootstrap resources are documented and partially implemented.
- AWS is present as a minimal foundation entry point, not a full platform build-out.
- Existing resources are classified as authoritative, legacy, deferred, or unmanaged before they enter long-term management.

See `infrastructure/docs/ADOPTION.md` for the current ownership boundary.

## Repository layout

```text
.
├── infrastructure/
│   ├── aws/                     # AWS foundation entry point and future environments
│   ├── azure/                   # Azure foundation, bootstrap, and homelab stacks
│   ├── docs/                    # Adoption, bootstrap, and verification docs
│   └── README.md                # Infrastructure-specific overview
├── openspec/                    # Approved specs and in-flight change proposals
├── .github/workflows/           # CI validation workflows
├── mise.toml                    # Local tool versions
└── README.md
```

## Prerequisites

- `mise` for installing pinned local tools from `mise.toml`
- `tofu` (OpenTofu)
- `az` for Azure work
- `aws` for AWS work

Install the core tooling with:

```bash
mise install
```

## Quick start

1. Install tools with `mise install`.
2. Authenticate to the cloud you plan to work in.
3. Choose the stack directory you want to inspect or change.
4. Run `tofu init` in that stack.
5. Run `tofu validate` and `tofu plan` before applying.

Example for the Azure homelab stack:

```bash
cd infrastructure/azure/homelab
tofu init
tofu validate
tofu plan
```

## Common workflows

### Validate infrastructure locally

After changing OpenTofu files, format the repo and then run validation:

```bash
tofu fmt -check -recursive infrastructure

cd infrastructure/azure
tofu init -backend=false
tofu validate

cd ../aws
tofu init -backend=false
tofu validate
```

This mirrors the current pull request checks in `.github/workflows/infrastructure-validate.yml`. That shared validation workflow does not run on push events.

### Bootstrap Azure remote state

The Azure bootstrap stack creates the storage account and container used for OpenTofu state.

```bash
cd infrastructure/azure/bootstrap
tofu init -backend=false
tofu plan
tofu apply
tofu init -migrate-state -backend-config=backend.hcl
```

After bootstrap, other Azure stacks can migrate to their own state keys in the shared backend.

### Work on the Azure homelab stack

The Azure homelab stack captures the current homelab support infrastructure and related adoption work.

Read `infrastructure/azure/homelab/README.md` before importing or applying brownfield changes.

## Change management

This repo uses OpenSpec to document infrastructure intent before or alongside implementation.

- OpenSpec project: `https://github.com/Fission-AI/OpenSpec`
- Local change artifacts live in `openspec/`

## Key docs

- `infrastructure/README.md` - infrastructure tree overview
- `infrastructure/docs/BOOTSTRAP.md` - backend, OIDC, and CI conventions
- `infrastructure/docs/ADOPTION.md` - ownership boundaries and adoption states
- `infrastructure/docs/VERIFICATION.md` - first-wave scope and exclusions
- `infrastructure/azure/bootstrap/README.md` - Azure remote state bootstrap workflow
- `infrastructure/aws/bootstrap/README.md` - AWS remote state and OIDC bootstrap workflow
- `infrastructure/azure/homelab/README.md` - Azure homelab import and workload identity details

## Notes

- Shared CI validation currently runs on qualifying pull requests, not push events. It checks formatting, runs `tofu init -backend=false`, and runs `tofu validate` for the Azure and AWS roots.
- The AWS bootstrap workflow runs offline validation on pull requests and automatic apply on `main` for `infrastructure/aws/bootstrap/**` changes.
- Non-destructive plan automation is documented but not fully wired for every stack yet.
- Secret values and long-lived cloud credentials are intentionally kept out of this repo.
- The AWS side is intentionally minimal until a later foundation change expands it.
