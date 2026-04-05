# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor) working in this repository.

---

## Purpose

Terraform lab for **enterprise-style AWS networking** using two emulators:

| Environment | Emulator | Endpoint |
|-------------|----------|----------|
| `environments/dev` | MiniStack | `http://localhost:4566` |
| `environments/prod` | LocalStack Pro | `http://localhost:4567` |

`prod` is the main multi-pattern scenario: VPC peering, PrivateLink, Transit Gateway hub–spoke, 3-tier edge VPC (IGW → public / app / data).

---

## Lab scope (production-oriented focus)

Use **`docs/subnet.csv`** for CIDRs. Intended learning areas:

- **Identity**: IAM (roles, policies, instance profiles), STS (implicit via provider / `GetCallerIdentity` patterns).
- **Data & edge**: S3 (bucket, separate bucket policy, versioning, encryption, public access block).
- **Edge protection**: WAF v2 (Web ACL, IP set, association) — see `modules/waf-v2`.
- **EC2 networking**: VPC, subnets, Internet Gateway, NAT gateway, egress-only IGW, route tables & routes, VPC endpoints (when used), VPC peering / TGW / PrivateLink (via `prod` modules).
- **EC2 attachments**: Security Groups (explicit rules), Elastic IPs, ENIs, key pairs, instances (lab patterns; no real VMs on emulators).
- **Core hardening (always in scope for this lab)**: **Network ACLs**, **VPC Flow Logs**, **EBS** (volumes/snapshots as used by patterns).

API-level gaps vs emulators: **[docs/support.md](docs/support.md)** (authoritative matrix).

---

## Repository layout

```text
docs/
  report.md
  subnet.csv              # CIDR source of truth
  support.md               # MiniStack vs LocalStack Pro API coverage
environments/
  dev/                     # MiniStack, ap-southeast-1, :4566
  prod/                    # LocalStack Pro, multi-region, :4567
modules/
  vpc-base/
  vpc-peering/
  privatelink/
  transit-gateway/
  waf-v2/
```

- Each `environments/*` directory is a **standalone** Terraform root module.
- `prod/` composes `vpc-peering`, `privatelink`, `transit-gateway`, plus edge VPC and optional WAF.

---

## Runbook (after Terraform / module / script changes)

1. **Start emulators**

```bash
./scripts/setup.sh
```

Requires **`LOCALSTACK_AUTH_TOKEN`** in the environment for LocalStack Pro (export locally, or GitHub Actions **Repository secret** — never commit tokens).

2. **Health**

```bash
curl -sf http://localhost:4566/_localstack/health
curl -sf http://localhost:4567/_localstack/health   # if token was set
# Optional (MiniStack native):
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

If `LOCALSTACK_AUTH_TOKEN` is unset, `setup.sh` still starts MiniStack; **full `prod` verification** needs the token.

---

## Provider rules (all environments)

- Keep **`endpoints { ... }`** overrides pointing at the correct emulator ports.
- Keep:
  - `skip_credentials_validation = true`
  - `skip_metadata_api_check = true`
  - `skip_requesting_account_id = true`
  - `access_key = "test"` / `secret_key = "test"`
- Never use real AWS credentials, real account IDs, or real ARNs in lab code.

### `hashicorp/aws` version and MiniStack

- Use **`>= 4.0, < 4.67`** (see `providers.tf`) so `aws_vpc` refresh does not call **`DescribeVpcClassicLink`** (missing on MiniStack). See [docs/support.md](docs/support.md).
- Other gaps: **`DescribeAddressesAttribute`** on `aws_eip` — still document in `support.md`; same pin helps avoid provider drift.
- **Commit** `environments/dev/.terraform.lock.hcl` and `environments/prod/.terraform.lock.hcl` so CI resolves the same build.
- AWS provider **5.x/6.x** on `dev` needs MiniStack to implement missing EC2 read APIs, or use workarounds in `support.md`.

---

## Known emulation limitations (short)

| Resource | Where | Issue | Workaround |
|----------|-------|-------|------------|
| `aws_ec2_transit_gateway_peering_attachment_accepter` | LocalStack Pro | Provider waiter on `DescribeTransitGatewayPeeringAttachments` may never complete during apply. | Set `enable_tgw_cross_region_peering = false` in `modules/transit-gateway` / `prod/terraform.tfvars` (default). Real AWS may use `true`. |

Full tables: **[docs/support.md](docs/support.md)**. MiniStack upstream: [releases](https://github.com/Nahuel990/ministack/releases).

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

---

## Emulation compatibility (summary)

| Capability | MiniStack (`dev`) | LocalStack Pro (`prod`) |
|------------|-------------------|---------------------------|
| EC2 / VPC core | Good | Good |
| VPC peering | Basic | Better parity |
| Transit Gateway | Limited | Supported |
| PrivateLink | Limited | Supported |
| IAM enforcement | Not real AWS | Emulated |

When behavior differs from AWS:

```hcl
# NOTE: Emulator limitation - what differs and why this resource is still useful in the lab
```

---

## Code style and security

- 2-space indentation; `snake_case` for Terraform names.
- No secrets in `.tf` or `terraform.tfvars`; keep `.tfstate` ignored.
- `LOCALSTACK_AUTH_TOKEN` only via environment / CI secrets.

---

## Linting (tflint)

```bash
which tflint || echo "tflint not installed"
tflint --init
tflint --recursive
```

---

## Clarification-first

If the target (`dev` vs `prod`) is unclear, ask one short question before coding.

## Strictly avoid

- Provider version upgrades unless asked or documented in `support.md` / this file.
- Renaming/moving resources between modules unless asked.
- Inventing CIDRs without `docs/subnet.csv`.
- Manual state file edits.
- Unrelated large diffs.

---

## Docs

- [docs/support.md](docs/support.md) — API coverage matrix and workarounds
- [docs/changelog.md](docs/changelog.md)
- [docs/report.md](docs/report.md)
