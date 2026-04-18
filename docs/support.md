# MiniStack — API Support Matrix

> MiniStack: **latest** (`ministackorg/ministack:latest`)
> Docker Hub: <https://hub.docker.com/r/ministackorg/ministack>

This document lists the AWS APIs used by this lab and their MiniStack support status. Since the latest MiniStack release covers all APIs required by this project (including `DescribeVpcClassicLink` and `DescribeAddressesAttribute`), the lab runs entirely on MiniStack.

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Supported |
| ⚠️ | Partial / stub only |

---

## S3

| Operation | MiniStack | Notes |
|---|---|---|
| CreateBucket | ✅ | |
| DeleteBucket | ✅ | |
| ListBuckets | ✅ | |
| HeadBucket | ✅ | |
| PutObject / GetObject / DeleteObject | ✅ | |
| HeadObject / CopyObject | ✅ | |
| ListObjects v1/v2 | ✅ | |
| DeleteObjects (batch) | ✅ | |
| Multipart Upload (Create/Upload/Complete/Abort) | ✅ | |
| Versioning (Get/Put/ListObjectVersions) | ✅ | |
| Encryption (Get/Put/Delete) | ✅ | |
| Lifecycle (Get/Put/Delete) | ✅ | |
| CORS (Get/Put/Delete) | ✅ | |
| ACL (Get/Put) | ✅ | |
| Tagging (Get/Put/Delete) | ✅ | |
| Policy (Get/Put/Delete) | ✅ | |
| NotificationConfiguration (Get/Put) | ✅ | |
| Logging (Get/Put) | ✅ | |
| Replication (Get/Put/Delete) | ✅ | |
| Object Lock (Put/Get Configuration, Retention, LegalHold) | ✅ | |
| S3 disk persistence | ✅ | `S3_PERSIST=1` |
| S3 Control ListTagsForResource | ✅ | |

---

## IAM

| Operation | MiniStack | Notes |
|---|---|---|
| CreateUser / GetUser / ListUsers / DeleteUser | ✅ | |
| CreateRole / GetRole / ListRoles / DeleteRole | ✅ | |
| CreatePolicy / GetPolicy / DeletePolicy | ✅ | |
| AttachRolePolicy / DetachRolePolicy | ✅ | |
| PutRolePolicy / GetRolePolicy / DeleteRolePolicy / ListRolePolicies | ✅ | |
| ListAttachedRolePolicies | ✅ | |
| CreateAccessKey / ListAccessKeys / DeleteAccessKey | ✅ | |
| InstanceProfile (Create/Get/Delete/Add/Remove/List) | ✅ | |
| Groups (Create/Get/AddUser/RemoveUser) | ✅ | |
| CreateServiceLinkedRole | ✅ | |
| CreateOpenIDConnectProvider | ✅ | |
| Tag/Untag (Role, User, Policy) | ✅ | |
| IAM policy enforcement | ⚠️ | MiniStack does not enforce IAM policies like real AWS |

---

## STS

| Operation | MiniStack | Notes |
|---|---|---|
| GetCallerIdentity | ✅ | |
| AssumeRole | ✅ | |
| GetSessionToken | ✅ | |
| AssumeRoleWithWebIdentity | ✅ | |

---

## WAF v2

| Operation | MiniStack | Notes |
|---|---|---|
| CreateWebACL / GetWebACL / UpdateWebACL / DeleteWebACL / ListWebACLs | ✅ | `LockToken` required on Update/Delete |
| AssociateWebACL / DisassociateWebACL | ✅ | |
| GetWebACLForResource / ListResourcesForWebACL | ✅ | |
| CreateIPSet / GetIPSet / UpdateIPSet / DeleteIPSet / ListIPSets | ✅ | `LockToken` required |
| CreateRuleGroup / GetRuleGroup / UpdateRuleGroup / DeleteRuleGroup / ListRuleGroups | ✅ | `LockToken` required |
| TagResource / UntagResource / ListTagsForResource | ✅ | |
| CheckCapacity / DescribeManagedRuleGroup | ✅ | |

---

## EC2 — Instances & Images

| Operation | MiniStack | Notes |
|---|---|---|
| RunInstances / DescribeInstances / TerminateInstances | ✅ | In-memory only, no real VMs |
| StopInstances / StartInstances / RebootInstances | ✅ | |
| DescribeImages | ✅ | |
| DescribeInstanceAttribute | ✅ | instanceType, userData, blockDeviceMapping, groupSet, etc. |
| DescribeInstanceTypes | ✅ | 12 instance families |
| DescribeInstanceCreditSpecifications | ✅ | Terraform v6 compatible |
| DescribeInstanceMaintenanceOptions | ✅ | Terraform v6 compatible |
| DescribeInstanceAutoRecoveryAttribute | ✅ | Terraform v6 compatible |
| ModifyInstanceMaintenanceOptions | ✅ | |
| DescribeInstanceTopology | ✅ | |
| DescribeSpotInstanceRequests | ✅ | |
| DescribeCapacityReservations | ✅ | |
| DescribeAvailabilityZones | ✅ | |
| DescribeTags / CreateTags / DeleteTags | ✅ | |
| DescribeInstanceStatus | ✅ | |
| **DescribeVpcClassicLink** | ✅ | Required by Terraform `aws_vpc` refresh with provider ≥ 4.67 |
| **DescribeVpcClassicLinkDnsSupport** | ✅ | |

---

## EC2 — Security Groups

| Operation | MiniStack | Notes |
|---|---|---|
| CreateSecurityGroup / DeleteSecurityGroup | ✅ | Default SG always present |
| DescribeSecurityGroups | ✅ | vpc-id/group-name filters |
| AuthorizeSecurityGroupIngress / RevokeSecurityGroupIngress | ✅ | Rules stored, not enforced |
| AuthorizeSecurityGroupEgress / RevokeSecurityGroupEgress | ✅ | Rules stored, not enforced |
| DescribeSecurityGroupRules | ✅ | Required by Terraform provider for SG rule refresh |

---

## EC2 — VPC & Subnets

| Operation | MiniStack | Notes |
|---|---|---|
| CreateVpc / DescribeVpcs / DeleteVpc | ✅ | Per-VPC default resources (RT, NACL, SG) auto-created |
| ModifyVpcAttribute / DescribeVpcAttribute | ✅ | EnableDnsSupport, EnableDnsHostnames |
| CreateSubnet / DeleteSubnet / DescribeSubnets / ModifySubnetAttribute | ✅ | |
| CreateVpcEndpoint / DeleteVpcEndpoints / DescribeVpcEndpoints / ModifyVpcEndpoint | ✅ | S3 Gateway + KMS/STS Interface |
| CreateVpcPeeringConnection / AcceptVpcPeeringConnection | ✅ | |
| DescribeVpcPeeringConnections / DeleteVpcPeeringConnection | ✅ | |

---

## EC2 — Internet Gateway & Routing

| Operation | MiniStack | Notes |
|---|---|---|
| CreateInternetGateway / DeleteInternetGateway / DescribeInternetGateways | ✅ | |
| AttachInternetGateway / DetachInternetGateway | ✅ | |
| CreateRouteTable / DeleteRouteTable / DescribeRouteTables | ✅ | |
| AssociateRouteTable / DisassociateRouteTable / ReplaceRouteTableAssociation | ✅ | |
| CreateRoute / ReplaceRoute / DeleteRoute | ✅ | |
| CreateNatGateway / DescribeNatGateways / DeleteNatGateway | ✅ | |
| CreateEgressOnlyInternetGateway / DescribeEgressOnlyInternetGateways / DeleteEgressOnlyInternetGateway | ✅ | |

---

## EC2 — Elastic IPs

| Operation | MiniStack | Notes |
|---|---|---|
| AllocateAddress / ReleaseAddress | ✅ | |
| AssociateAddress / DisassociateAddress | ✅ | |
| DescribeAddresses | ✅ | |
| **DescribeAddressesAttribute** | ✅ | Required by Terraform refresh of `aws_eip` |

---

## EC2 — Network Interfaces

| Operation | MiniStack | Notes |
|---|---|---|
| CreateNetworkInterface / DeleteNetworkInterface | ✅ | |
| DescribeNetworkInterfaces | ✅ | |
| AttachNetworkInterface / DetachNetworkInterface | ✅ | |

---

## EC2 — Key Pairs

| Operation | MiniStack | Notes |
|---|---|---|
| CreateKeyPair / DeleteKeyPair / DescribeKeyPairs / ImportKeyPair | ✅ | |

---

## EC2 — Network ACLs & Flow Logs

| Operation | MiniStack | Notes |
|---|---|---|
| CreateNetworkAcl / DescribeNetworkAcls / DeleteNetworkAcl | ✅ | vpc-id + default filter |
| CreateNetworkAclEntry / DeleteNetworkAclEntry / ReplaceNetworkAclEntry | ✅ | |
| ReplaceNetworkAclAssociation | ✅ | |
| CreateFlowLogs / DescribeFlowLogs / DeleteFlowLogs | ✅ | |

---

## EC2 — DHCP

| Operation | MiniStack | Notes |
|---|---|---|
| CreateDhcpOptions / AssociateDhcpOptions / DescribeDhcpOptions / DeleteDhcpOptions | ✅ | |

---

## EC2 — Launch Templates

| Operation | MiniStack | Notes |
|---|---|---|
| CreateLaunchTemplate / CreateLaunchTemplateVersion | ✅ | |
| DescribeLaunchTemplates / DescribeLaunchTemplateVersions | ✅ | |
| ModifyLaunchTemplate / DeleteLaunchTemplate | ✅ | Versioning with $Latest/$Default |

---

## EBS

| Operation | MiniStack | Notes |
|---|---|---|
| CreateVolume / DeleteVolume / DescribeVolumes / DescribeVolumeStatus | ✅ | |
| AttachVolume / DetachVolume / ModifyVolume / DescribeVolumesModifications | ✅ | |
| CreateSnapshot / DeleteSnapshot / DescribeSnapshots / CopySnapshot / ModifySnapshotAttribute | ✅ | |

---

## EC2 — Prefix Lists & Managed Prefix Lists

| Operation | MiniStack | Notes |
|---|---|---|
| DescribePrefixLists | ✅ | S3, DynamoDB service prefix lists |
| CreateManagedPrefixList / DescribeManagedPrefixLists / GetManagedPrefixListEntries | ✅ | |
| ModifyManagedPrefixList / DeleteManagedPrefixList | ✅ | |

---

## EC2 — VPN Gateways & Customer Gateways

| Operation | MiniStack | Notes |
|---|---|---|
| CreateVpnGateway / DescribeVpnGateways / AttachVpnGateway / DetachVpnGateway / DeleteVpnGateway | ✅ | |
| EnableVgwRoutePropagation / DisableVgwRoutePropagation | ✅ | |
| CreateCustomerGateway / DescribeCustomerGateways / DeleteCustomerGateway | ✅ | |

---

## ELBv2 / ALB

| Operation | MiniStack | Notes |
|---|---|---|
| CreateLoadBalancer / DescribeLoadBalancers / DeleteLoadBalancer | ✅ | Control + data plane |
| DescribeLoadBalancerAttributes / ModifyLoadBalancerAttributes | ✅ | |
| CreateTargetGroup / DescribeTargetGroups / ModifyTargetGroup / DeleteTargetGroup | ✅ | |
| DescribeTargetGroupAttributes / ModifyTargetGroupAttributes | ✅ | |
| CreateListener / DescribeListeners / ModifyListener / DeleteListener | ✅ | |
| CreateRule / DescribeRules / ModifyRule / DeleteRule / SetRulePriorities | ✅ | |
| RegisterTargets / DeregisterTargets / DescribeTargetHealth | ✅ | |
| AddTags / RemoveTags / DescribeTags | ✅ | |

---

## KMS

| Operation | MiniStack | Notes |
|---|---|---|
| CreateKey / ListKeys / DescribeKey | ✅ | |
| GetPublicKey / Sign / Verify | ✅ | RSA + ECC |
| Encrypt / Decrypt / GenerateDataKey / GenerateDataKeyWithoutPlaintext | ✅ | |
| CreateAlias / DeleteAlias / ListAliases / UpdateAlias | ✅ | |
| EnableKeyRotation / DisableKeyRotation / GetKeyRotationStatus | ✅ | |
| GetKeyPolicy / PutKeyPolicy / ListKeyPolicies | ✅ | |
| EnableKey / DisableKey / ScheduleKeyDeletion / CancelKeyDeletion | ✅ | |
| TagResource / UntagResource / ListResourceTags | ✅ | |

---

## Route53

| Operation | MiniStack | Notes |
|---|---|---|
| CreateHostedZone / GetHostedZone / ListHostedZones / DeleteHostedZone | ✅ | |
| ChangeResourceRecordSets / ListResourceRecordSets / GetChange | ✅ | |
| Health Checks (Create/Get/List/Delete/Update) | ✅ | |

---

## CloudFront

| Operation | MiniStack | Notes |
|---|---|---|
| CreateDistribution / GetDistribution / ListDistributions / UpdateDistribution / DeleteDistribution | ✅ | ETag concurrency control |
| Invalidation (Create/List/Get) | ✅ | |

---

## Lambda

| Operation | MiniStack | Notes |
|---|---|---|
| CreateFunction / GetFunction / ListFunctions / DeleteFunction / Invoke | ✅ | Python + Node.js runtimes |
| UpdateFunctionCode / UpdateFunctionConfiguration | ✅ | |
| PublishVersion / ListVersionsByFunction | ✅ | |
| CreateFunctionUrlConfig / GetFunctionUrlConfig / DeleteFunctionUrlConfig | ✅ | |
| EventSourceMapping (Create/Get/List/Update/Delete) | ✅ | SQS + Kinesis |
| Provided runtime (provided.al2023/al2) | ✅ | Docker RIE |

---

## Transit Gateway

| Operation | MiniStack | Notes |
|---|---|---|
| CreateTransitGateway | ❌ | Not implemented — `Unknown EC2 action` |
| DescribeTransitGateways | ❌ | Not implemented |
| CreateTransitGatewayVpcAttachment | ❌ | Not implemented |
| CreateTransitGatewayPeeringAttachment | ❌ | Not implemented |

**Workaround:** Set `enable_transit_gateway = false` in `environments/prod/terraform.tfvars` (default). The `modules/transit-gateway` module still creates VPCs, subnets, route tables, NAT gateways, and security groups — only the TGW resource itself and its attachments fail.

---

## VPC Endpoint Service (PrivateLink)

| Operation | MiniStack | Notes |
|---|---|---|
| CreateVpcEndpointServiceConfiguration | ❌ | Not implemented — `Unknown EC2 action` |
| DescribeVpcEndpointServiceConfigurations | ❌ | Not implemented |

**Workaround:** Set `enable_privatelink = false` in `environments/prod/terraform.tfvars` (default). The `modules/privatelink` module creates NLB, VPCs, subnets, and all networking — only the VPC Endpoint Service resource fails. NLB/ALB creation and listeners work fine.

---

## Transit Gateway Cross-Region Peering

**Resource:** `aws_ec2_transit_gateway_peering_attachment_accepter`

MiniStack does not support Transit Gateway APIs. Cross-region TGW peering is controlled by `enable_tgw_cross_region_peering` variable (defaults to `false`). The entire Transit Gateway module is controlled by `enable_transit_gateway` (defaults to `false`).

```hcl
# In environments/prod/terraform.tfvars
enable_transit_gateway          = false
enable_tgw_cross_region_peering = false
```

---

## Environment Context

| Emulator | Image | Port | Environment |
|----------|-------|------|-------------|
| MiniStack | `ministackorg/ministack:latest` | `:4566` | `environments/dev`, `environments/prod` |

---

## State Persistence

MiniStack supports state persistence when `PERSIST_STATE=1`:
- All services supported for persistence
- State saved on shutdown, restored on startup via atomic JSON files
- S3 persistence separate via `S3_PERSIST=1`

---

## Terraform AWS Provider Compatibility

MiniStack latest is compatible with **hashicorp/aws >= 5.0** (including v6.x). All previously missing APIs (`DescribeVpcClassicLink`, `DescribeAddressesAttribute`, `DescribeVpcAttribute`, `DescribeSecurityGroupRules`) are now supported.

This lab uses `>= 6.0`.
