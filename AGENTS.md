# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor) working in this repository.

---

## Purpose

Terraform lab for **enterprise-style AWS networking** using **MiniStack** — a free, open-source AWS emulator.

| Environment | Emulator | Endpoint |
|-------------|----------|----------|
| `environments/dev` | MiniStack | `http://localhost:4566` |
| `environments/prod` | MiniStack | `http://localhost:4566` |

Both environments use the same MiniStack instance. `prod` is the multi-pattern scenario: VPC peering, PrivateLink, Transit Gateway hub–spoke, 3-tier **main / ingress** VPC (`module.main_vpc`, IGW → public / app / data).

---

## Lab scope (production-oriented focus)

Use **`docs/subnet.csv`** for CIDRs. Intended learning areas:

- **Identity**: IAM (roles, policies, instance profiles), STS (implicit via provider / `GetCallerIdentity` patterns).
- **Data & edge**: S3 (bucket, separate bucket policy, versioning, encryption, public access block).
- **Edge protection**: WAF v2 (Web ACL, IP set, association) — see `modules/waf-v2`.
- **EC2 networking**: VPC, subnets, Internet Gateway, NAT gateway, egress-only IGW, route tables & routes, VPC endpoints (when used), VPC peering / TGW / PrivateLink (via `prod` modules).
- **EC2 attachments**: Security Groups (explicit rules), Elastic IPs, ENIs, key pairs, instances (lab patterns; no real VMs on emulators).
- **Core hardening (always in scope for this lab)**: **Network ACLs**, **VPC Flow Logs**, **EBS** (volumes/snapshots as used by patterns).

API-level details: **[docs/support.md](docs/support.md)** (authoritative matrix).

---

## Repository layout

```text
docs/
  report.md
  subnet.csv              # CIDR source of truth
  support.md               # MiniStack API coverage
environments/
  dev/                     # MiniStack, ap-southeast-1, :4566
  prod/                    # MiniStack, multi-region, :4566
iam/
  stg/                     # Cross-account SNS→SQS + IRSA (staging)
  prod/                    # Cross-account SNS→SQS fan-out + IRSA (prod)
modules/
  vpc-base/
  vpc-peering/
  privatelink/
  transit-gateway/
  waf-v2/
```

- Each `environments/*` directory is a **standalone** Terraform root module.
- `prod/` composes `vpc-peering`, `privatelink`, `transit-gateway`, plus **`main_vpc`** (ingress 3-tier) and optional WAF.

---

## Runbook (after Terraform / module / script changes)

1. **Start MiniStack**

```bash
./scripts/setup.sh
```

Uses `podman compose` (preferred) or `docker compose` as fallback.

2. **Health**

```bash
curl -sf http://localhost:4566/_ministack/health
```

3. **Validate dev and prod**

```bash
terraform -chdir=environments/dev fmt -check
terraform -chdir=environments/dev init -input=false
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev apply -auto-approve
terraform -chdir=environments/dev output
terraform -chdir=environments/dev destroy -auto-approve

terraform -chdir=environments/prod fmt -check
terraform -chdir=environments/prod init -input=false
terraform -chdir=environments/prod validate
terraform -chdir=environments/prod apply -auto-approve
terraform -chdir=environments/prod output
terraform -chdir=environments/prod destroy -auto-approve
```

4. **Stop**

```bash
./scripts/teardown.sh
```

---

## Provider rules (all environments)

- Keep **`endpoints { ... }`** overrides pointing at `http://localhost:4566`.
- Keep:
  - `skip_credentials_validation = true`
  - `skip_metadata_api_check = true`
  - `skip_requesting_account_id = true`
  - `access_key = "test"` / `secret_key = "test"`
- Never use real AWS credentials, real account IDs, or real ARNs in lab code.

### `hashicorp/aws` version and MiniStack

- Use **`>= 6.0`** — MiniStack latest supports all required APIs including `DescribeVpcClassicLink`, `DescribeAddressesAttribute`, `DescribeVpcAttribute`, and `DescribeSecurityGroupRules`.
- MiniStack is explicitly compatible with **Terraform AWS Provider v5 and v6**.
- **Commit** `environments/dev/.terraform.lock.hcl` and `environments/prod/.terraform.lock.hcl` so CI resolves the same build.

---

## Known emulation limitations (short)

| Resource | Issue | Workaround |
|----------|-------|------------|
| `aws_ec2_transit_gateway` | `CreateTransitGateway` not implemented | Set `enable_transit_gateway = false` (default) |
| `aws_vpc_endpoint_service` | `CreateVpcEndpointServiceConfiguration` not implemented | Set `enable_privatelink = false` (default) |
| `aws_ec2_transit_gateway_peering_attachment_accepter` | TGW peering waiter may not complete | Set `enable_tgw_cross_region_peering = false` (default) |
| IAM policy enforcement | MiniStack does not enforce IAM policies | Rules stored, not enforced — lab-only |

Full tables: **[docs/support.md](docs/support.md)**. MiniStack upstream: [releases](https://github.com/ministackorg/ministack/releases).

---

## Allowed and disallowed Terraform commands

**Allowed:** `init`, `fmt`, `fmt -check`, `validate`, `plan`, `test`, `output`, `state list`, `state show <addr>`.

**Disallowed:** `import`, `state mv`, `state rm`, `state push`, `state pull`.

Use `apply` / `destroy` only for **local emulator** validation and document intent.

---

## Module selection

1. `modules/vpc-base/` for VPC / subnet / route / IGW / NAT patterns.
2. Other `modules/*` when they fit.
3. Plain `resource` blocks only if no module fits.
4. External registry modules only when explicitly requested.

Do not add new providers or external modules without a clear request.

---

## Service-specific guidance

- **S3**: `aws_s3_bucket` + separate `aws_s3_bucket_policy`; add versioning, encryption, public access block unless the exercise needs public access.
- **EC2**: Explicit security groups; prefer separate ingress/egress rules; no hardcoded real AMIs (placeholders OK for emulators).
- **IAM**: `aws_iam_role` + `aws_iam_role_policy_attachment`; policies via `data "aws_iam_policy_document"`.
- **VPC**: Always align CIDRs with `docs/subnet.csv`.

### VPC naming and AWS VPC endpoints (`vpc-base`)

- **Prod VPC names in tfvars**: Peering and PrivateLink VPC **Name** tags come from **`peering_*_vpc_name`** and **`pl_*_vpc_name`** in `environments/prod` (defaults align with `docs/subnet.csv`). TGW hub **Name** tags use **`tgw_name_tag_region_*`**; spoke VPC names remain **map keys** in `tgw_spokes_region_*`. Inventory table: [docs/README.md](docs/README.md) **§1.3**.
- **Naming and diagrams**: Use [docs/README.md](docs/README.md) — **§1.2 *Network conventions*** for landing zone vs spoke, VPC naming table, and Gateway vs Interface endpoint diagrams. Renaming existing VPCs in Terraform can force replacement; use the conventions for **new** resources or planned migrations.
- **Endpoints in code**: `modules/vpc-base` exposes optional flags: **S3 Gateway** (app + data route tables), **KMS** and **STS Interface** (app subnets, dedicated SG for TCP 443 from the VPC CIDR, `private_dns_enabled = true`). **Gateway** = route-table–based; **Interface** = ENI in subnets.
- **Tagging**: New endpoint and SG resources must use `merge(local.default_tags, { Name = ... })` like other `vpc-base` resources (see **Resource tagging (AWS)** below).
- **Conventions drift**: When you introduce new lab-wide naming or endpoint rules, update **this file** and the long-form **README §1.2** together so agents and humans have one checklist and one narrative.

---

## Emulation compatibility (summary)

| Capability | MiniStack |
|------------|-----------|
| EC2 / VPC core | ✅ Full (136 actions) |
| VPC peering | ✅ |
| Transit Gateway | ❌ `CreateTransitGateway` not implemented |
| PrivateLink (VPC Endpoint Service) | ❌ `CreateVpcEndpointServiceConfiguration` not implemented |
| ELBv2 / ALB / NLB | ✅ (control + data plane) |
| WAF v2 | ✅ |
| IAM enforcement | ⚠️ Not enforced (stored only) |
| Terraform provider >= 6.0 | ✅ Compatible |

**Module toggles in `environments/prod/terraform.tfvars`:**
- `enable_transit_gateway = false` — skips `modules/transit-gateway` (TGW API missing)
- `enable_privatelink = false` — skips `modules/privatelink` (VPC Endpoint Service API missing)
- `enable_tgw_cross_region_peering = false` — only relevant when TGW is enabled

When behavior differs from AWS:

```hcl
# NOTE: Emulator limitation - what differs and why this resource is still useful in the lab
```

---

## Code style and security

- 2-space indentation; `snake_case` for Terraform names.
- No secrets in `.tf` or `terraform.tfvars`; keep `.tfstate` ignored.

### Resource tagging (AWS) — always apply

When adding or editing Terraform under `modules/`, follow the same pattern as existing modules (see [docs/README.md](docs/README.md), section *Resource tagging (AWS)*):

- In each module, define `local.module_label = basename(abspath(path.module))` and `local.default_tags = merge(var.tags, { TerraformModule = local.module_label })`.
- Use `merge(local.default_tags, { Name = ... })` (and any other per-resource tags) on resources that support `tags`. **Do not** hardcode the module name in `TerraformModule`; always derive it with `basename(abspath(path.module))`.
- New modules must include this `locals` block and pass `var.tags` from the root module as today.
- Root environments continue to set `default_tags` on the `aws` provider for `Project`, `Environment`, `ManagedBy`; do not duplicate those keys unnecessarily on every resource unless your change requires an override.

---

## Container runtime

This lab uses **Podman** (preferred) or Docker as fallback. Scripts auto-detect `podman-compose` → `podman compose` → `docker compose`.

Docker Hub image: **`ministackorg/ministack:latest`**

---

## Linting (tflint)

Run **after any Terraform change** (modules or `environments/*`) and before pushing; CI uses the same rules via `.tflint.hcl`. Fix all issues (warnings are errors for merge hygiene).

```bash
which tflint || echo "tflint not installed"
tflint --init
tflint --recursive
```

---

## Clarification-first

If the target (`dev` vs `prod`) is unclear, ask one short question before coding.

## Strictly avoid

- Renaming/moving resources between modules unless asked.
- Inventing CIDRs without `docs/subnet.csv`.
- Manual state file edits.
- Unrelated large diffs.

---

## Docs

- [docs/README.md](docs/README.md) — includes **§1.1** (tagging), **§1.2** (landing zone vs spoke, endpoints), **§1.3** (prod VPC inventory / tfvars map)
- [docs/support.md](docs/support.md) — API coverage matrix and workarounds
- [docs/README.md](docs/README.md) — Architecture analysis
