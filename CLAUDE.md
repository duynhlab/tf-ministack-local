# AGENTS.md

Guidance for AI coding agents working in this repository.

---

## Purpose

Terraform networking lab for enterprise-like AWS patterns using dual emulators:

- `environments/dev` -> MiniStack (`http://localhost:4566`)
- `environments/prod` -> LocalStack Pro (`http://localhost:4567`)

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
|  `- subnet.csv
|- environments/
|  |- dev/
|  `- prod/
`- modules/
   |- vpc-base/
   |- vpc-peering/
   |- privatelink/
   `- transit-gateway/
```

Rules:

- `environments/*` are standalone root modules.
- CIDR allocation must come from `docs/subnet.csv` (never invent CIDRs).
- Reuse `modules/vpc-base` before creating new VPC primitives.

---

## Emulator mapping

| Environment | Emulator | Endpoint |
|---|---|---|
| `environments/dev` | MiniStack | `http://localhost:4566` |
| `environments/prod` | LocalStack Pro | `http://localhost:4567` |

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

3. Verify `dev`:

```bash
terraform -chdir=environments/dev fmt -check
terraform -chdir=environments/dev init -input=false
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev apply -auto-approve
terraform -chdir=environments/dev output
terraform -chdir=environments/dev destroy -auto-approve
```

4. Verify `prod`:

```bash
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

Never run:

- `terraform import`
- `terraform state mv`
- `terraform state rm`
- `terraform state push`
- `terraform state pull`

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

## Verification checklist (apply -> verify -> destroy)

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

# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor) working in this repository.

---

## Purpose

Learning and prototyping AWS infrastructure patterns using Terraform.

**This repository is designed for enterprise emulation using MiniStack by default, with LocalStack Pro fallback for unsupported APIs.**
All environments simulate real AWS topology locally.

| Target | Environments | Credentials | Endpoints | State backend |
|--------|-------------|-------------|-----------|---------------|
| **MiniStack** (Default Emulation) | `dev/`, `vpc-peering/` | dummy `test`/`test` | `http://localhost:4566` | local |
| **LocalStack Pro** (Fallback Emulation) | `privatelink/`, `transit-gateway/`, `prod/` | dummy `test`/`test` + `LOCALSTACK_AUTH_TOKEN` | `http://localhost:4566` | local |

**Scope:** Networking (VPC, VPC Peering, Transit Gateway, PrivateLink), Compute (EC2, Security Groups),
Storage (S3, bucket policies), Identity (IAM roles, policies, instance profiles).

---

## Repository layout

```
tf-test/
├── docs/
│   ├── report.md
│   └── subnet.csv             # IP allocation table — consult before assigning CIDRs
├── environments/
│   ├── dev/                   # MiniStack Emulation — ap-southeast-1 (Singapore)
│   │   ├── providers.tf       # Must include localhost endpoints & test credentials
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── prod/                  # LocalStack Pro fallback (composed connectivity scenarios)
│   │   ├── providers.tf       # Must include localhost endpoints & test credentials
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── vpc-peering/           # MiniStack focused
│   ├── privatelink/           # LocalStack Pro fallback (endpoint service API)
│   └── transit-gateway/       # LocalStack Pro fallback (TGW API)
└── modules/
    ├── vpc-base/              # Single VPC for dev — reuse before writing new VPC resources
    ├── vpc-peering/
    ├── privatelink/
    └── transit-gateway/
```

**Key rules:**
- Each `environments/*` directory is a **standalone root module** — init and operate independently.
- `docs/subnet.csv` is the source of truth for CIDR allocation. Always check it before
  proposing any subnet or VPC CIDR — never invent an address range.
- When adding a new environment, mirror the file structure of `dev/` as the baseline.
- If `prod/` is getting a feature that `dev/` does not have yet, flag it explicitly.

---

## Environment context & provider rules

### All Environments (`dev/`, `prod/`, `vpc-peering/`, `transit-gateway/`, `privatelink/`)

- Provider must include `endpoints {}` override block and these flags — **do not remove them:**
  ```hcl
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  access_key                  = "test"
  secret_key                  = "test"
  ```
- State backend: local state by default in this repository.
- Never use real AWS credentials or real ARNs in any environment.
- `dev/` uses `ap-southeast-1` to simulate a fully-scaled 3-tier VPC with 3 Availability Zones.
- `prod/` targets multi-region emulation for peering, PrivateLink, and TGW patterns.
- Start emulator via `scripts/setup.sh` before verify/test; choose emulator by `EMULATOR=ministack|localstack`.

---

## Emulator runbook

### Start / stop

- Start MiniStack (default):
  ```bash
  EMULATOR=ministack ./scripts/setup.sh
  ```
- Start LocalStack Pro fallback:
  ```bash
  EMULATOR=localstack LOCALSTACK_AUTH_TOKEN=<your_token> ./scripts/setup.sh
  ```
- Teardown container only:
  ```bash
  EMULATOR=ministack ./scripts/teardown.sh
  # or
  EMULATOR=localstack ./scripts/teardown.sh
  ```
- Teardown container + terraform destroy for all env roots:
  ```bash
  CONFIRM_DESTROY=1 EMULATOR=ministack ./scripts/teardown.sh
  # or
  CONFIRM_DESTROY=1 EMULATOR=localstack ./scripts/teardown.sh
  ```

Health check for either emulator:
```bash
curl -sf http://localhost:4566/_localstack/health
```

### Environment-to-emulator mapping

| Environment | Primary module(s) | Emulator |
|-------------|-------------------|----------|
| `environments/dev` | `modules/vpc-base` | MiniStack |
| `environments/vpc-peering` | `modules/vpc-peering` | MiniStack |
| `environments/privatelink` | `modules/privatelink` | LocalStack Pro fallback |
| `environments/transit-gateway` | `modules/transit-gateway` | LocalStack Pro fallback |
| `environments/prod` | peering + privatelink + transit-gateway | LocalStack Pro fallback |

### Verification checklist (apply -> verify -> destroy)

After adjusting any Terraform/module/provider/script behavior:

1. Start emulator with `scripts/setup.sh` using the right `EMULATOR=`.
2. For each target environment:
   - `terraform -chdir=environments/<env> fmt -check`
   - `terraform -chdir=environments/<env> init -input=false`
   - `terraform -chdir=environments/<env> validate`
   - `terraform -chdir=environments/<env> apply -auto-approve` (human-reviewed run)
   - Verify outputs and AWS CLI checks
   - `terraform -chdir=environments/<env> destroy -auto-approve` (human-reviewed run)
3. Stop emulator with `scripts/teardown.sh`.

---

## Allowed commands per environment

### All Environments

Agents **MAY** suggest or run:

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
terraform apply
terraform destroy
```

> If `apply` or `destroy` is genuinely required, explain what it does and why,
> then stop and let the human run it.

---

## State & backend

- **MiniStack environments**: prefer local state for lab workflows. Never propose manual state edits.
- **Real AWS environments**: backend TBD — do not assume or add one without being asked.
- If a resource address needs to change (rename, move between modules):
  *"This requires a manual `terraform state mv` — review carefully before running."*
- Never propose any kind of manual state file edit.

---

## Module selection rules

Before writing a new resource block, check in this order:

1. **`modules/vpc-base/`** — always check first for any VPC/subnet/route table resource.
2. **Other existing modules in `modules/`** — prefer reuse and extension.
3. **Plain `resource` blocks** — acceptable if no module fits; briefly explain why.
4. **External registry modules** — only if the user explicitly asks; note emulation
   compatibility risk for MiniStack environments.

Never introduce new providers or external modules on your own initiative.

### Per-service guidance

**S3**
- `aws_s3_bucket` + separate `aws_s3_bucket_policy` — never inline `policy` on the bucket.
- Always pair with `aws_s3_bucket_versioning` and `aws_s3_bucket_server_side_encryption_configuration`.
- Always add `aws_s3_bucket_public_access_block` unless the exercise explicitly requires public access.
- Bucket names: lowercase, no underscores; use a `var.name_suffix` or `local` for uniqueness.
- Real AWS (`dev/`, `prod/`): bucket names must be globally unique — include environment and region suffix.

**EC2**
- Always attach an explicit Security Group — never reference the default SG.
- Ingress/egress rules: use separate `aws_vpc_security_group_ingress_rule` /
  `aws_vpc_security_group_egress_rule` resources (not inline `ingress {}` / `egress {}` blocks).
- AMIs: use `data "aws_ami"` lookup or a variable — never hardcode an AMI ID.
  - MiniStack: `data "aws_ami"` may not resolve; use a variable with comment:
    `# MiniStack: any non-empty string, e.g. "ami-00000000"`
  - Real AWS (`dev/`): use `data "aws_ami"` filtering scoped to `ap-southeast-1`.
- Always place instances in a private subnet unless a public IP is explicitly required.
- Attach an `aws_iam_instance_profile` when the instance needs AWS API access.

**IAM**
- `aws_iam_role` + `aws_iam_role_policy_attachment` — do not use inline `aws_iam_role_policy`
  unless the policy is strictly one-off and non-reusable.
- Reusable policies: `aws_iam_policy` resource, then attach.
- Instance profiles: always create an explicit `aws_iam_instance_profile`; never assume the
  role name doubles as a profile name.
- All policy JSON via `data "aws_iam_policy_document"` — never raw heredoc strings.
- Least-privilege: scope `Resource` to specific ARNs, not `"*"`, unless the exercise
  explicitly demonstrates wildcard behavior.
- Real AWS: never use `AdministratorAccess` managed policy in any module code.

**VPC / Networking**
- Always check `docs/subnet.csv` before assigning any CIDR block.
- New VPCs must use `modules/vpc-base/` unless there is a documented reason not to.
- Route tables: one route table per subnet tier (public / private / isolated).
- NAT Gateway: define in module and verify support with `terraform plan` in emulation first.

---

## Emulation compatibility rules

- Prefer resource types and arguments that the selected emulator supports. When uncertain:
  *"Emulator support for `X` may be limited — verify with `terraform plan` first."*
- Do not add `depends_on` workarounds for AWS eventual-consistency; flag unexpected behavior instead.

### Service-specific emulation notes

| Service | Emulation support |
|---------|------------------------------|
| **S3** | Fully supported for common CRUD and bucket configuration APIs. |
| **EC2** | Instance/SG/key pair creation supported. Use `t3.micro`. User data does **not** execute. |
| **IAM** | CRUD fully supported. Policy enforcement is **not** simulated — API calls are not permission-checked. |
| **VPC Peering** | Basic peering accepted; route propagation not enforced at network level. |
| **Transit Gateway** | Use LocalStack Pro fallback for stable TGW API coverage. |
| **PrivateLink** | Use LocalStack Pro fallback for endpoint service APIs (`aws_vpc_endpoint_service`). |
| **NAT Gateway** | API is available but behavior differs from real AWS; validate with `terraform plan`. |

When hitting a limitation, annotate in the `.tf` file:

```hcl
# NOTE: MiniStack limitation — <what does not work and why the resource is still useful to define>
```

---

## Code style

- 2-space indentation throughout.
- Naming: `snake_case` for all variables, locals, resources, and outputs.
- Resource labels: descriptive, no abbreviations (`vpc_peering_requester`, not `vpcpr`).
- One resource type per file where practical (`vpc.tf`, `subnets.tf`, `routes.tf`, `sg.tf`).
- Standard file layout per environment/module:

  ```
  main.tf          # resource blocks and module calls
  variables.tf     # input variable declarations
  outputs.tf       # output declarations
  providers.tf     # provider and backend configuration
  terraform.tfvars # variable values (never commit secrets here)
  ```

- When adding a new `environments/*` dir, copy the structure from `dev/` as the baseline.

---

