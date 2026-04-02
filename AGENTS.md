# AGENTS.md

Guidance for AI coding agents working in this repository.

---

## Purpose

Terraform networking lab for enterprise-like AWS patterns using dual emulators:

| Environment | Emulator | Endpoint |
|---|---|---|
| `environments/dev` | MiniStack | `http://localhost:4566` |
| `environments/prod` | LocalStack Pro | `http://localhost:4567` |

`prod` is the main "real-work" scenario and must include all core networking use-cases:

1. VPC Peering
2. PrivateLink
3. Transit Gateway hub-spoke multi-VPC
4. 3-tier edge VPC (client -> IGW -> public/app/data)

---

## Repository layout

```text
tf-test/
|- docs/
|  |- report.md
|  `- subnet.csv             # IP allocation table - consult before assigning CIDRs
|- environments/
|  |- dev/                   # MiniStack emulation (ap-southeast-1, :4566)
|  |  |- providers.tf
|  |  |- main.tf
|  |  |- variables.tf
|  |  |- outputs.tf
|  |  `- terraform.tfvars
|  `- prod/                  # LocalStack Pro emulation (multi-region, :4567)
|     |- providers.tf
|     |- main.tf
|     |- variables.tf
|     |- outputs.tf
|     `- terraform.tfvars
`- modules/
   |- vpc-base/
   |- vpc-peering/
   |- privatelink/
   `- transit-gateway/
```

Key rules:
- Each `environments/*` directory is a standalone root module.
- `docs/subnet.csv` is the source of truth for CIDR allocation.
- `prod/` composes `vpc-peering`, `privatelink`, and `transit-gateway` modules for real-world learning flows.

---
## Target Architecture
### dev/
  - Single VPC (basic networking)
  - Used for quick validation

### prod/
Enterprise-style topology:
  - 3-tier VPC:
    - Public (IGW)
    - App (private)
    - Data (isolated)
  - Hub-spoke via Transit Gateway
  - VPC Peering
  - PrivateLink

---

## Runbook (required workflow)

After any Terraform/module/script adjustment, follow this exact flow.

1. Start containers:

```bash
./scripts/setup.sh
```

2. Verify health:

```bash
curl -sf http://localhost:4566/_localstack/health
curl -sf http://localhost:4567/_localstack/health
```

3. Verify `dev` and `prod`

```bash
# dev
terraform -chdir=environments/dev fmt -check
terraform -chdir=environments/dev init -input=false
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev apply -auto-approve
terraform -chdir=environments/dev output
terraform -chdir=environments/dev destroy -auto-approve

# prod 
terraform -chdir=environments/prod fmt -check
terraform -chdir=environments/prod init -input=false
terraform -chdir=environments/prod validate
terraform -chdir=environments/prod apply -auto-approve
terraform -chdir=environments/prod output
terraform -chdir=environments/prod destroy -auto-approve
```

5. Stop containers:

```bash
./scripts/teardown.sh
```

Notes:

- `LOCALSTACK_AUTH_TOKEN` is required to start LocalStack Pro and run `prod`.
- If token is missing, only `dev` can be fully verified.

---

## Provider rules

For all environments:

- Keep endpoint overrides.
- Keep:
  - `skip_credentials_validation = true`
  - `skip_metadata_api_check = true`
  - `skip_requesting_account_id = true`
  - `access_key = "test"`
  - `secret_key = "test"`
- Never use real AWS credentials, account IDs, or real ARNs.

---

## Allowed and disallowed Terraform commands

Allowed:

- `terraform init`
- `terraform fmt`
- `terraform fmt -check`
- `terraform validate`
- `terraform plan`
- `terraform test`
- `terraform output`
- `terraform state list`
- `terraform state show <addr>`


---

## Networking-specific guidance

- Keep focus on networking primitives only (VPC, subnet, route table, IGW, NAT, SG, peering, TGW, PrivateLink).
- `prod` should reflect company-style topology:
  - internet ingress at edge/public tier
  - app tier private
  - data tier isolated
  - hub-spoke scaling through TGW
- Avoid introducing EKS/app-platform scope unless explicitly asked.

## Known emulation limitations

| Resource | Emulator | Issue | Workaround |
|----------|----------|-------|------------|
| `aws_ec2_transit_gateway_peering_attachment_accepter` | LocalStack Pro | Terraform provider's internal waiter polls `DescribeTransitGatewayPeeringAttachments` indefinitely; the state never reaches `available` during concurrent apply (CLI works standalone). No configurable timeout on this resource. | `enable_cross_region_peering = false` in `modules/transit-gateway` (default in `prod/terraform.tfvars`). Both TGWs + all spokes still deploy; only the cross-region peering link is skipped. Set `true` for real AWS. |

### Provider compatibility note (lint/docs)
- For MiniStack (`environments/dev`), pin provider to `hashicorp/aws` 4.x to avoid missing EC2 API actions (`DescribeVpcAttribute`, `DescribeAddressesAttribute`).
- For LocalStack Pro (`environments/prod`), v5/v6 can work once MiniStack compatibility is not required.
- Track MiniStack releases: https://github.com/Nahuel990/ministack/releases

---

## Security and style

- 2-space indentation.
- `snake_case` for Terraform identifiers.
- No secrets in `.tf` files or `terraform.tfvars`.
- Keep changes scoped; avoid unrelated refactors.

# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor) working in this repository.

---

## Purpose

Learning and prototyping AWS infrastructure patterns using Terraform with dual emulators:

- `environments/dev` uses **MiniStack** on `http://localhost:4566`
- `environments/prod` uses **LocalStack Pro** on `http://localhost:4567`

Both emulator containers run at the same time.

| Target | Environments | Credentials | Endpoints | State backend |
|--------|-------------|-------------|-----------|---------------|
| **MiniStack** | `dev/` | dummy `test`/`test` | `http://localhost:4566` | local |
| **LocalStack Pro** | `prod/` | dummy `test`/`test` | `http://localhost:4567` | local / S3 |

**Scope:** Networking (VPC, VPC Peering, Transit Gateway, PrivateLink), Compute (EC2, Security Groups), Storage (S3, bucket policies), Identity (IAM roles, policies, instance profiles).

---

## Repository layout

```text
tf-test/
|- docs/
|  |- report.md
|  `- subnet.csv             # IP allocation table - consult before assigning CIDRs
|- environments/
|  |- dev/                   # MiniStack emulation (ap-southeast-1, :4566)
|  |  |- providers.tf
|  |  |- main.tf
|  |  |- variables.tf
|  |  |- outputs.tf
|  |  `- terraform.tfvars
|  `- prod/                  # LocalStack Pro emulation (multi-region, :4567)
|     |- providers.tf
|     |- main.tf
|     |- variables.tf
|     |- outputs.tf
|     `- terraform.tfvars
`- modules/
   |- vpc-base/
   |- vpc-peering/
   |- privatelink/
   `- transit-gateway/
```

Key rules:
- Each `environments/*` directory is a standalone root module.
- `docs/subnet.csv` is the source of truth for CIDR allocation.
- `prod/` composes `vpc-peering`, `privatelink`, and `transit-gateway` modules for real-world learning flows.

---

## Emulator runbook

Start emulators:

```bash
./scripts/setup.sh
```

Health checks:

```bash
curl http://localhost:4566/_localstack/health
curl http://localhost:4567/_localstack/health
```

Stop emulators:

```bash
./scripts/teardown.sh
```

Environment-to-emulator mapping:

| Environment | Emulator | Host endpoint |
|-------------|----------|---------------|
| `environments/dev` | MiniStack | `http://localhost:4566` |
| `environments/prod` | LocalStack Pro | `http://localhost:4567` |

Notes:
- `LOCALSTACK_AUTH_TOKEN` is required only for LocalStack Pro (`prod` flows).
- If token is missing, `setup.sh` still starts MiniStack for `dev` workflows.

---

## Environment context and provider rules

### All environments (`dev/`, `prod/`)

- Provider must include `endpoints {}` override block and these flags; do not remove:
  - `skip_credentials_validation = true`
  - `skip_metadata_api_check = true`
  - `skip_requesting_account_id = true`
  - `access_key = "test"`
  - `secret_key = "test"`
- Never use real AWS credentials, real account IDs, or real ARNs.

### `dev/` (MiniStack)

- Region: `ap-southeast-1`
- Endpoint: `http://localhost:4566`
- Primary module target: `modules/vpc-base`

### `prod/` (LocalStack Pro)

- Multi-region emulation
- Endpoint: `http://localhost:4567`
- Uses `modules/vpc-peering`, `modules/privatelink`, and `modules/transit-gateway`
- Requires `LOCALSTACK_AUTH_TOKEN`

---

## Allowed Terraform commands

Agents may suggest or run:

```bash
terraform init
terraform fmt
terraform fmt -check
terraform validate
terraform plan
terraform test
terraform state list
terraform state show <addr>
terraform output
```

Never suggest or run:

```bash
terraform import
terraform state mv
terraform state rm
terraform state push
terraform state pull
```

If `apply`/`destroy` is needed for validation, explain intent clearly and keep usage scoped to controlled local emulation workflows.

---

## Module selection rules

Before writing a new resource block, check in this order:

1. `modules/vpc-base/` for VPC/subnet/route table resources
2. Existing modules under `modules/`
3. Plain `resource` blocks if no module fits
4. External registry modules only when explicitly requested

Do not introduce new providers or external modules on your own initiative.

---

## Service-specific guidance

### S3
- Use `aws_s3_bucket` plus separate `aws_s3_bucket_policy` (no inline bucket policy).
- Add `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`, and `aws_s3_bucket_public_access_block` unless the exercise explicitly needs public access.

### EC2
- Always use explicit Security Group resources.
- Prefer separate ingress/egress rule resources.
- Do not hardcode AMI IDs for real AWS.
- For emulation, an AMI variable placeholder is acceptable.

### IAM
- Prefer `aws_iam_role` + `aws_iam_role_policy_attachment`.
- Build policies using `data "aws_iam_policy_document"`.
- Follow least privilege; avoid wildcard resources unless explicitly required by the exercise.

### VPC / Networking
- Always check `docs/subnet.csv` before assigning CIDRs.
- Reuse `modules/vpc-base` for new VPC patterns unless there is a documented exception.

---

## Emulation compatibility notes

| Capability | MiniStack (`dev`) | LocalStack Pro (`prod`) |
|------------|-------------------|--------------------------|
| EC2/VPC core resources | Good | Good |
| VPC Peering | Basic behavior | Better parity |
| Transit Gateway | Limited | Supported |
| PrivateLink endpoint service | Limited | Supported |
| IAM policy enforcement fidelity | Limited | Limited (emulated) |

When behavior differs from AWS, add a short inline note in Terraform code:

```hcl
# NOTE: Emulator limitation - describe what differs and why this resource is still useful in the lab
```

---

## Code style

- 2-space indentation.
- `snake_case` naming for variables, locals, resources, outputs.
- Descriptive resource labels; avoid opaque abbreviations.
- Keep environment/module file layout consistent (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `terraform.tfvars`).

---

## Security and secrets

- Never hardcode credentials, tokens, passwords, or account IDs in Terraform files.
- `terraform.tfvars` must not contain secrets.
- Keep `.tfstate` / `.tfstate.backup` ignored.
- `LOCALSTACK_AUTH_TOKEN` must come from environment variables only.

---
## Linting with tflint
```bash
# Verify tflint is installed
which tflint || echo "tflint not installed"

# Check for .tflint.hcl configuration
ls -la .tflint.hcl
```

Standard Linting Process

```bash
# Initialise tflint (first time or when plugins change)
tflint --init

# Run linting on current directory
tflint

# Run with more detailed output
tflint --format compact

# Run recursively on all modules
tflint --recursive
```


---
## Verification and Development (apply -> verify -> destroy)

1. `./scripts/setup.sh`
2. Verify health:
   - `curl http://localhost:4566/_localstack/health`
   - `curl http://localhost:4567/_localstack/health` (if token is set)
3. Dev:
   - `terraform -chdir=environments/dev init -input=false`
   - `terraform -chdir=environments/dev apply -auto-approve`
   - `terraform -chdir=environments/dev output`
   - `terraform -chdir=environments/dev destroy -auto-approve`
4. Prod (requires token):
   - `terraform -chdir=environments/prod init -input=false`
   - `terraform -chdir=environments/prod apply -auto-approve`
   - `terraform -chdir=environments/prod output`
   - `terraform -chdir=environments/prod destroy -auto-approve`
5. `./scripts/teardown.sh`

---

## Clarification-first rule

If a request is ambiguous, ask one short clarifying question before writing code, especially when it is unclear whether the target is `dev` (MiniStack) or `prod` (LocalStack Pro).

---

## Strictly avoid

- Proposing provider version upgrades unless asked
- Renaming/moving resources between modules unless asked
- Inventing CIDR blocks without reading `docs/subnet.csv`
- Manual state file editing
- Broad, unrelated diffs


## Docs 
- ./docs/support.md
- ./docs/changelog.md
- ./docs/report.md
 