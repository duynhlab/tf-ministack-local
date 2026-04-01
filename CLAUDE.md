# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor, Windsurf) working in this repository.

---

## Purpose

Learning and prototyping AWS infrastructure patterns using Terraform.

**This repo targets two distinct backends — always confirm which one before writing code:**

| Target | Environments | Credentials | State backend |
|--------|-------------|-------------|---------------|
| **LocalStack** (local emulation) | `vpc-peering/`, `transit-gateway/`, `privatelink/` | dummy `mock`/`mock` | LocalStack S3 bucket |
| **Real AWS** | `dev/` (ap-southeast-1), `prod/` (multi-region) | real IAM credentials | TBD — do not assume; ask |

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
│   ├── dev/                   # Real AWS — ap-southeast-1 (Singapore)
│   │   ├── providers.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── prod/                  # Real AWS — multi-region
│   │   ├── providers.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── vpc-peering/           # LocalStack only
│   ├── privatelink/           # LocalStack only
│   └── transit-gateway/       # LocalStack only
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

### LocalStack environments (`vpc-peering/`, `transit-gateway/`, `privatelink/`)

- Provider must include `endpoints {}` override block and these flags — **do not remove them:**
  ```hcl
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  access_key                  = "mock"
  secret_key                  = "mock"
  ```
- State backend: LocalStack S3 bucket. Bucket must exist before `terraform init`;
  check `scripts/` for bootstrap helpers.
- Never use real AWS credentials or real ARNs in LocalStack environments.

### Real AWS environments (`dev/`, `prod/`)

- Provider must **not** contain LocalStack endpoint overrides or dummy credentials.
- Credentials come from environment variables (`AWS_PROFILE` / `AWS_ACCESS_KEY_ID`) or
  an assumed IAM role — never hardcoded in `.tf` files.
- `dev/` → region `ap-southeast-1`. `prod/` → multi-region; check `providers.tf` for
  alias configuration before adding resources.
- State backend is TBD. Do not add or modify `backend {}` blocks without being explicitly asked.
  When asked, propose **S3 + DynamoDB locking** as the default option, explain the tradeoffs,
  and wait for confirmation before writing code.

---

## Allowed commands per environment

### LocalStack environments

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
```

### `dev/` (real AWS)

Agents **MAY** suggest or run:

```bash
terraform init
terraform fmt
terraform fmt -check
terraform validate
terraform plan          # allowed — real AWS, review output carefully
terraform state list    # read-only
terraform state show <addr>
terraform output
```

### `prod/` (real AWS — restricted)

Agents **MAY** suggest:

```bash
terraform fmt
terraform fmt -check
terraform validate
terraform state list    # read-only
terraform state show <addr>
terraform output
```

Agents **MUST ask the human before suggesting** on `prod/`:

```bash
terraform init          # ask first — backend config may need review
terraform plan          # ask first — confirm scope before touching prod state
```

### All environments — never suggest or run

```bash
terraform apply         # no apply without human review
terraform destroy       # no destroy without human review
terraform import        # no import
terraform state mv      # no state surgery
terraform state rm      # no state surgery
terraform state push    # no state surgery
terraform state pull    # no state surgery (use list/show)
```

> If `apply` or `destroy` is genuinely required, explain what it does and why,
> then stop and let the human run it.

---

## State & backend

- **LocalStack environments**: S3 backend pointing at LocalStack. Never propose manual state edits.
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
4. **External registry modules** — only if the user explicitly asks; note LocalStack
   compatibility risk for LocalStack environments.

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
  - LocalStack: `data "aws_ami"` may not resolve; use a variable with comment:
    `# LocalStack: any non-empty string, e.g. "ami-00000000"`
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
- NAT Gateway: define in module but default `enable_nat_gateway = false` for LocalStack
  (not supported); set `true` only when explicitly working in real AWS.

---

## LocalStack compatibility rules

- Prefer resource types and arguments that LocalStack Community supports. When uncertain:
  *"LocalStack support for `X` may be limited — verify with `terraform plan` first."*
- Do not add `depends_on` workarounds for AWS eventual-consistency; flag unexpected behavior instead.

### Service-specific LocalStack notes

| Service | LocalStack Community support |
|---------|------------------------------|
| **S3** | Fully supported. Bucket notifications, Object Lambda, Multi-Region Access Points need Pro. |
| **EC2** | Instance/SG/key pair creation supported. Use `t3.micro`. User data does **not** execute. |
| **IAM** | CRUD fully supported. Policy enforcement is **not** simulated — API calls are not permission-checked. |
| **VPC Peering** | Basic peering accepted; route propagation not enforced at network level. |
| **Transit Gateway** | Partial — attachments created; actual packet routing not simulated. |
| **PrivateLink** | Endpoint creation accepted; DNS resolution to private IPs does not work locally. |
| **NAT Gateway** | Not supported in Community; guard with `count = var.enable_nat ? 1 : 0`. |

When hitting a limitation, annotate in the `.tf` file:

```hcl
# NOTE: LocalStack limitation — <what does not work and why the resource is still useful to define>
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

## Security & secrets

- Never hardcode credentials, tokens, passwords, or account IDs in any `.tf` file or
  `variables.tf` default — including dummy LocalStack values outside the provider block.
- `terraform.tfvars` must not contain secrets; use environment variables or a secrets manager.
- `.tfstate` and `.tfstate.backup` must be in `.gitignore` — verify before committing.
- Real AWS: never put real account IDs, real ARNs, or real region-specific resource IDs
  directly in module code; parameterize via variables.
- LocalStack: dummy credentials (`access_key = "mock"`) belong only in the `provider` block.

---

## Output style

- Minimal, directly-runnable code snippets.
- No "here's a high-level idea" without a working Terraform example alongside it.
- Skip long explanations unless explicitly requested.
- When referencing an existing pattern, cite the file path:
  *"mirrors `environments/dev/main.tf`"*.

---

## Clarification-first rule

If the request is ambiguous — **especially if it is unclear whether the target is LocalStack
or real AWS** — ask one short clarifying question before writing any code. Do not guess the
target environment.

---

## Strictly avoid

- Proposing provider version upgrades unless asked.
- Renaming or moving resources between modules unless asked.
- Suggesting `terraform apply` or `terraform destroy` as a casual next step.
- Inventing CIDR blocks — always read `docs/subnet.csv` first.
- Adding `backend {}` blocks to real AWS environments without being asked.
- Generating large diffs that touch unrelated files.
- Using `AdministratorAccess` or wildcard `Resource: "*"` in real AWS IAM code.

---
