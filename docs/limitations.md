# Emulator Limitations — MiniStack vs LocalStack Pro

Observed behavior for every AWS resource/API used in this project's four modules
(`vpc-base`, `vpc-peering`, `privatelink`, `transit-gateway`) and two environments
(`dev` on MiniStack, `prod` on LocalStack Pro).

| Emulator | Image | Port | Environment |
|----------|-------|------|-------------|
| MiniStack | `nahuelnucera/ministack:latest` | `:4566` | `environments/dev` |
| LocalStack Pro | `localstack/localstack-pro:latest` | `:4567` | `environments/prod` |

---

## Resource Compatibility Matrix

| Category | Resource / API | MiniStack (dev, :4566) | LocalStack Pro (prod, :4567) | Notes |
|----------|---------------|----------------------|----------------------------|-------|
| VPC Core | `aws_vpc`, `aws_subnet`, `aws_route_table`, `aws_route` | Works | Works | |
| VPC Core | `aws_internet_gateway` | Works | Works | |
| VPC Core | `aws_eip` | Works | Works | |
| VPC Core | `aws_nat_gateway` | Works | Works | |
| VPC Core | `aws_security_group` (inline ingress/egress) | Works | Works | |
| VPC Core | `aws_route_table_association` | Works | Works | |
| VPC Core | `data "aws_availability_zones"` | Works | Works | |
| EC2 API | `DescribeVpcAttribute` | **Fails** (`InvalidAction: Unknown EC2 action`) | Works | MiniStack does not implement this API; causes `terraform apply` to error during resource refresh |
| EC2 API | `DescribeAddressesAttribute` | **Fails** (`InvalidAction: Unknown EC2 action`) | Works | Same root cause as above |
| Provider compatibility | `hashicorp/aws` 4.x | ✅ | ✅ | Required for MiniStack due missing EC2 API actions (`DescribeVpcAttribute`, `DescribeAddressesAttribute`) |
| VPC Peering | `aws_vpc_peering_connection` | Not tested (dev is single-region) | Works | |
| VPC Peering | `aws_vpc_peering_connection_accepter` (`auto_accept = true`) | Not tested | Works | Completes instantly; no polling waiter |
| VPC Peering | Cross-region routes (`aws_route` with `vpc_peering_connection_id`) | Not tested | Works | |
| PrivateLink | `aws_lb` (NLB, `load_balancer_type = "network"`) | Not tested | Works | Creation takes ~60s |
| PrivateLink | `aws_lb_target_group`, `aws_lb_listener` | Not tested | Works | |
| PrivateLink | `aws_vpc_endpoint_service` | Not tested | Works | |
| PrivateLink | `aws_vpc_endpoint` (Interface type) | Not tested | Works | |
| Transit Gateway | `aws_ec2_transit_gateway` | Not tested | Works | Both region A and B |
| Transit Gateway | `aws_ec2_transit_gateway_vpc_attachment` | Not tested | Works | |
| Transit Gateway | `aws_route` (via `transit_gateway_id`) | Not tested | Works | |
| Transit Gateway | `aws_ec2_transit_gateway_peering_attachment` | Not tested | Works | Creates with `state = pendingAcceptance` |
| Transit Gateway | `aws_ec2_transit_gateway_peering_attachment_accepter` | Not tested | **HANGS indefinitely** | See detailed analysis below |
| Multi-Region | Two aliased providers pointing to same endpoint | N/A (single provider) | Works | Different `region` arg, same `:4567` host |
| IAM | Policy enforcement | Not simulated | Not simulated | API calls accepted but not permission-checked |

---

## Detailed Issue: TGW Cross-Region Peering Accepter Hang

**Resource:** `aws_ec2_transit_gateway_peering_attachment_accepter`
**Module:** `modules/transit-gateway` (lines 312-318)
**Observed in:** `environments/prod` on LocalStack Pro

### Symptom

`terraform apply` hangs at:

```
module.transit_gateway.aws_ec2_transit_gateway_peering_attachment_accepter.cross_region: Still creating... [02m40s elapsed]
```

The process never completes and must be killed manually.

### Root Cause

1. Terraform provider calls `AcceptTransitGatewayPeeringAttachment` -- LocalStack accepts it and returns `State: available`.
2. Provider then enters an **internal waiter** that polls `DescribeTransitGatewayPeeringAttachments` waiting for state `available`.
3. During a concurrent `terraform apply` (90+ resources), the Describe call does not return the expected `available` state from the provider's waiter perspective.
4. The `aws_ec2_transit_gateway_peering_attachment_accepter` resource has **no configurable `timeouts {}` block** -- the waiter runs indefinitely.

**Diagnostic note:** The AWS CLI `accept-transit-gateway-peering-attachment` and `describe-transit-gateway-peering-attachments` both work correctly when called in isolation (state transitions to `available`). The hang only occurs during concurrent Terraform apply.

### Contrast with VPC Peering (which works)

`aws_vpc_peering_connection_accepter` uses `auto_accept = true`. The provider reads back the status immediately without a polling waiter, so it completes instantly on LocalStack.

### Workaround

```hcl
# In modules/transit-gateway/variables.tf
variable "enable_cross_region_peering" {
  type    = bool
  default = true   # set false for LocalStack
}

# In environments/prod/terraform.tfvars
enable_tgw_cross_region_peering = false
```

Both TGWs, all spoke VPCs, VPC attachments, and routes still deploy. Only the cross-region peering link is skipped. Set `true` for real AWS.

---

## Detailed Issue: MiniStack Missing EC2 APIs

**Observed in:** `environments/dev` on MiniStack

### Symptom

`terraform apply` fails with:

```
InvalidAction: Unknown EC2 action: DescribeVpcAttribute
InvalidAction: Unknown EC2 action: DescribeAddressesAttribute
```

### Root Cause

MiniStack does not implement these EC2 API actions. They are called by the Terraform AWS provider during resource refresh for `aws_vpc` and `aws_eip` resources.

### Workaround

Use `terraform destroy -refresh=false -lock=false` to clean up partial state if apply fails.
The `terraform plan` and `terraform validate` steps work fine; only `apply` (which triggers refresh) hits these APIs.

---

## Recovery Procedures

### After a hung `terraform apply`

```bash
# 1. Kill the hung process
kill <PID>

# 2. Kill any lingering provider processes
ps aux | grep tfprovider | grep -v grep | awk '{print $2}' | xargs -r kill -9

# 3. Remove stale lock file
rm -f environments/prod/.terraform.tfstate.lock.info

# 4. Destroy with lock bypass
terraform -chdir=environments/prod destroy -auto-approve -lock=false

# 5. Verify clean state
terraform -chdir=environments/prod state list
```

### After a failed MiniStack apply

```bash
terraform -chdir=environments/dev destroy -auto-approve -refresh=false -lock=false
```
