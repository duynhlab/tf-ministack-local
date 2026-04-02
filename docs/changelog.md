# Changelog (Terraform AWS provider compatibility)

## 2026-04-02

- `environments/dev/providers.tf`:
  - `aws` provider pinned to `~> 4.70` (MiniStack compatibility)
- `environments/prod/providers.tf`:
  - `aws` provider pinned to `~> 4.70` (LocalStack Pro compatibility in repo workflow)
- Modules:
  - `modules/vpc-base/main.tf`
  - `modules/vpc-peering/main.tf`
  - `modules/privatelink/main.tf`
  - `modules/transit-gateway/main.tf`
  - Updated `required_providers` to support `aws` provider `>= 4.70`.

### Root cause

MiniStack currently does not support some EC2 APIs that Terraform AWS Provider v5/v6 relies on during refresh:
- `DescribeVpcAttribute` (used by `aws_vpc` for `enable_dns_hostnames` / `enable_dns_support`)
- `DescribeAddressesAttribute` (used by `aws_eip`)

Result:
- `terraform apply` in `environments/dev` fails with `InvalidAction: Unknown EC2 action`
- `aws_vpc` / `aws_eip` resources cannot complete creation.

### Upgrade path

- If running on LocalStack Pro or real AWS, v5/v6 can be used.
- For MiniStack-based local lab, keep `~> 4.70` to avoid blocked apply due to missing EC2 APIs.
- If you want to try `~> 6.0`, change provider version and run `terraform plan`/`apply`; report a bug if it fails.
- When a new MiniStack release adds support for `DescribeVpcAttribute` and `DescribeAddressesAttribute`, migrate to latest provider (e.g. `~> 6.0`) and remove the workaround.
  - Monitor: https://github.com/Nahuel990/ministack/releases
