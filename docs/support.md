# MiniStack vs LocalStack — Service Comparison

> MiniStack: **v1.1.17**
> LocalStack Pro: **latest**

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Supported |
| ❌ | Not supported / Missing |
| ⚠️ | Partial / stub only |

---

## S3

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateBucket | ✅ | ✅ | v1.0.0+ | |
| DeleteBucket | ✅ | ✅ | v1.0.0+ | |
| ListBuckets | ✅ | ✅ | v1.0.0+ | |
| HeadBucket | ✅ | ✅ | v1.0.0+ | |
| PutObject | ✅ | ✅ | v1.0.0+ | |
| GetObject | ✅ | ✅ | v1.0.0+ | |
| DeleteObject | ✅ | ✅ | v1.0.0+ | |
| HeadObject | ✅ | ✅ | v1.0.0+ | |
| CopyObject | ✅ | ✅ | v1.0.0+ | |
| ListObjects v1/v2 | ✅ | ✅ | v1.0.0+ | |
| DeleteObjects (batch) | ✅ | ✅ | v1.0.0+ | |
| CreateMultipartUpload | ✅ | ✅ | v1.0.0+ | |
| UploadPart | ✅ | ✅ | v1.0.0+ | |
| CompleteMultipartUpload | ✅ | ✅ | v1.0.0+ | |
| AbortMultipartUpload | ✅ | ✅ | v1.0.0+ | |
| GetBucketVersioning | ✅ | ✅ | v1.0.0+ | |
| PutBucketVersioning | ✅ | ✅ | v1.0.0+ | |
| ListObjectVersions | ✅ | ✅ | v1.0.0+ | |
| GetBucketEncryption | ✅ | ✅ | v1.0.0+ | |
| PutBucketEncryption | ✅ | ✅ | v1.0.0+ | |
| DeleteBucketEncryption | ✅ | ✅ | v1.0.0+ | |
| GetBucketLifecycleConfiguration | ✅ | ✅ | v1.0.0+ | |
| PutBucketLifecycleConfiguration | ✅ | ✅ | v1.0.0+ | |
| DeleteBucketLifecycle | ✅ | ✅ | v1.0.0+ | |
| GetBucketCors | ✅ | ✅ | v1.0.0+ | |
| PutBucketCors | ✅ | ✅ | v1.0.0+ | |
| DeleteBucketCors | ✅ | ✅ | v1.0.0+ | |
| GetBucketAcl | ✅ | ✅ | v1.0.0+ | |
| PutBucketAcl | ✅ | ✅ | v1.0.0+ | |
| GetBucketTagging | ✅ | ✅ | v1.0.0+ | |
| PutBucketTagging | ✅ | ✅ | v1.0.0+ | |
| DeleteBucketTagging | ✅ | ✅ | v1.0.0+ | |
| GetBucketPolicy | ✅ | ✅ | v1.0.0+ | |
| PutBucketPolicy | ✅ | ✅ | v1.0.0+ | |
| DeleteBucketPolicy | ✅ | ✅ | v1.0.0+ | |
| GetBucketNotificationConfiguration | ✅ | ✅ | v1.0.0+ | |
| PutBucketNotificationConfiguration | ✅ | ✅ | v1.0.0+ | |
| GetBucketLogging | ✅ | ✅ | v1.0.0+ | |
| PutBucketLogging | ✅ | ✅ | v1.0.0+ | |
| GetBucketReplication | ✅ | ✅ | v1.0.0+ | |
| PutBucketReplication | ✅ | ✅ | v1.0.0+ | |
| DeleteBucketReplication | ✅ | ✅ | v1.0.0+ | |
| PutObjectLockConfiguration | ✅ | ✅ | v1.0.0+ | MiniStack enforces retention & legal hold on delete |
| GetObjectLockConfiguration | ✅ | ✅ | v1.0.0+ | |
| PutObjectRetention | ✅ | ✅ | v1.0.0+ | |
| GetObjectRetention | ✅ | ✅ | v1.0.0+ | |
| PutObjectLegalHold | ✅ | ✅ | v1.0.0+ | |
| GetObjectLegalHold | ✅ | ✅ | v1.0.0+ | |
| S3 disk persistence | ✅ | ✅ | v1.0.0+ | MiniStack: `S3_PERSIST=1` — LocalStack Pro: bật mặc định |
| S3 Control ListTagsForResource | ✅ | ✅ | v1.1.14 | MiniStack fix: trả đúng tags thay vì empty list |

---

## IAM

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateUser | ✅ | ✅ | v1.0.0+ | |
| GetUser | ✅ | ✅ | v1.0.0+ | |
| ListUsers | ✅ | ✅ | v1.0.0+ | |
| DeleteUser | ✅ | ✅ | v1.0.0+ | |
| CreateRole | ✅ | ✅ | v1.0.0+ | |
| GetRole | ✅ | ✅ | v1.0.0+ | |
| ListRoles | ✅ | ✅ | v1.0.0+ | |
| DeleteRole | ✅ | ✅ | v1.0.0+ | |
| CreatePolicy | ✅ | ✅ | v1.0.0+ | |
| GetPolicy | ✅ | ✅ | v1.0.0+ | |
| DeletePolicy | ✅ | ✅ | v1.0.0+ | |
| AttachRolePolicy | ✅ | ✅ | v1.0.0+ | |
| DetachRolePolicy | ✅ | ✅ | v1.0.0+ | |
| PutRolePolicy (inline) | ✅ | ✅ | v1.0.0+ | |
| GetRolePolicy | ✅ | ✅ | v1.0.0+ | |
| DeleteRolePolicy | ✅ | ✅ | v1.0.0+ | |
| ListRolePolicies | ✅ | ✅ | v1.0.0+ | |
| ListAttachedRolePolicies | ✅ | ✅ | v1.0.0+ | |
| CreateAccessKey | ✅ | ✅ | v1.0.0+ | |
| ListAccessKeys | ✅ | ✅ | v1.0.0+ | |
| DeleteAccessKey | ✅ | ✅ | v1.0.0+ | |
| CreateInstanceProfile | ✅ | ✅ | v1.0.0+ | |
| GetInstanceProfile | ✅ | ✅ | v1.0.0+ | |
| DeleteInstanceProfile | ✅ | ✅ | v1.0.0+ | |
| AddRoleToInstanceProfile | ✅ | ✅ | v1.0.0+ | |
| RemoveRoleFromInstanceProfile | ✅ | ✅ | v1.0.0+ | |
| ListInstanceProfiles | ✅ | ✅ | v1.0.0+ | |
| CreateGroup | ✅ | ✅ | v1.0.0+ | |
| GetGroup | ✅ | ✅ | v1.0.0+ | |
| AddUserToGroup | ✅ | ✅ | v1.0.0+ | |
| RemoveUserFromGroup | ✅ | ✅ | v1.0.0+ | |
| CreateServiceLinkedRole | ✅ | ✅ | v1.0.0+ | |
| CreateOpenIDConnectProvider | ✅ | ✅ | v1.0.0+ | |
| TagRole / UntagRole | ✅ | ✅ | v1.0.0+ | |
| TagUser / UntagUser | ✅ | ✅ | v1.0.0+ | |
| TagPolicy / UntagPolicy | ✅ | ✅ | v1.0.0+ | |
| IAM policy enforcement | ❌ | ✅ | — | MiniStack không enforce IAM policy thật |

---

## STS

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| GetCallerIdentity | ✅ | ✅ | v1.0.0+ | |
| AssumeRole | ✅ | ✅ | v1.0.0+ | |
| GetSessionToken | ✅ | ✅ | v1.0.0+ | |
| AssumeRoleWithWebIdentity | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Instances & Images

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| RunInstances | ✅ | ✅ | v1.0.0+ | MiniStack: in-memory only, không có VM thật |
| DescribeInstances | ✅ | ✅ | v1.0.0+ | |
| TerminateInstances | ✅ | ✅ | v1.0.0+ | |
| StopInstances | ✅ | ✅ | v1.0.0+ | |
| StartInstances | ✅ | ✅ | v1.0.0+ | |
| RebootInstances | ✅ | ✅ | v1.0.0+ | |
| DescribeImages | ✅ | ✅ | v1.0.0+ | |
| DescribeInstanceAttribute | ✅ | ✅ | v1.1.14 | Fix Terraform AWS Provider ≥ 6.0.0; hỗ trợ instanceType, userData, blockDeviceMapping, groupSet, v.v. |
| DescribeInstanceTypes | ✅ | ✅ | v1.1.14 | 12 instance families: t2, t3, m5, c5, r5, p3, v.v. |
| DescribeInstanceCreditSpecifications | ✅ | ✅ | v1.1.17 | Terraform v6 provider compatible stub for CPU credits |
| DescribeInstanceMaintenanceOptions | ✅ | ✅ | v1.1.17 | Terraform v6 provider compatibility stub |
| DescribeInstanceAutoRecoveryAttribute | ✅ | ✅ | v1.1.17 | Terraform v6 provider compatibility stub |
| ModifyInstanceMaintenanceOptions | ✅ | ✅ | v1.1.17 | Terraform v6 provider compatibility stub |
| DescribeInstanceTopology | ✅ | ✅ | v1.1.17 | Terraform v6 provider compatibility stub |
| DescribeSpotInstanceRequests | ✅ | ✅ | v1.1.17 | Terraform v6 provider compatibility stub |
| DescribeCapacityReservations | ✅ | ✅ | v1.1.17 | Terraform v6 provider compatibility stub |
| DescribeAvailabilityZones | ✅ | ✅ | v1.0.0+ | |
| DescribeTags / CreateTags / DeleteTags | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Security Groups

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateSecurityGroup | ✅ | ✅ | v1.0.0+ | Default SG luôn có sẵn |
| DeleteSecurityGroup | ✅ | ✅ | v1.0.0+ | |
| DescribeSecurityGroups | ✅ | ✅ | v1.0.0+ | |
| AuthorizeSecurityGroupIngress | ✅ | ✅ | v1.0.0+ | Rules stored, không enforced trên cả 2 |
| RevokeSecurityGroupIngress | ✅ | ✅ | v1.0.0+ | |
| AuthorizeSecurityGroupEgress | ✅ | ✅ | v1.0.0+ | |
| RevokeSecurityGroupEgress | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — VPC & Subnets

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateVpc | ✅ | ✅ | v1.0.0+ | Default VPC luôn có sẵn |
| DeleteVpc | ✅ | ✅ | v1.0.0+ | |
| DescribeVpcs | ✅ | ✅ | v1.0.0+ | |
| ModifyVpcAttribute | ✅ | ✅ | v1.0.0+ | Lưu EnableDnsSupport / EnableDnsHostnames vào state |
| **DescribeVpcAttribute** | ❌ | ✅ | — | **Missing** — `InvalidAction` khi Terraform refresh `aws_vpc` |
| CreateSubnet | ✅ | ✅ | v1.0.0+ | Default subnet luôn có sẵn |
| DeleteSubnet | ✅ | ✅ | v1.0.0+ | |
| DescribeSubnets | ✅ | ✅ | v1.0.0+ | |
| ModifySubnetAttribute | ✅ | ✅ | v1.0.0+ | |
| CreateVpcEndpoint | ✅ | ✅ | v1.0.0+ | |
| DeleteVpcEndpoints | ✅ | ✅ | v1.0.0+ | |
| DescribeVpcEndpoints | ✅ | ✅ | v1.0.0+ | |
| CreateVpcPeeringConnection | ✅ | ✅ | v1.0.0+ | |
| AcceptVpcPeeringConnection | ✅ | ✅ | v1.0.0+ | |
| DescribeVpcPeeringConnections | ✅ | ✅ | v1.0.0+ | |
| DeleteVpcPeeringConnection | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Internet Gateway & Routing

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateInternetGateway | ✅ | ✅ | v1.0.0+ | Default IGW luôn có sẵn |
| DeleteInternetGateway | ✅ | ✅ | v1.0.0+ | |
| DescribeInternetGateways | ✅ | ✅ | v1.0.0+ | |
| AttachInternetGateway | ✅ | ✅ | v1.0.0+ | |
| DetachInternetGateway | ✅ | ✅ | v1.0.0+ | |
| CreateRouteTable | ✅ | ✅ | v1.0.0+ | Default route table luôn có sẵn |
| DeleteRouteTable | ✅ | ✅ | v1.0.0+ | |
| DescribeRouteTables | ✅ | ✅ | v1.0.0+ | |
| AssociateRouteTable | ✅ | ✅ | v1.0.0+ | |
| DisassociateRouteTable | ✅ | ✅ | v1.0.0+ | |
| CreateRoute | ✅ | ✅ | v1.0.0+ | |
| ReplaceRoute | ✅ | ✅ | v1.0.0+ | |
| DeleteRoute | ✅ | ✅ | v1.0.0+ | |
| CreateNatGateway | ✅ | ✅ | v1.0.0+ | |
| DescribeNatGateways | ✅ | ✅ | v1.0.0+ | |
| DeleteNatGateway | ✅ | ✅ | v1.0.0+ | |
| CreateEgressOnlyInternetGateway | ✅ | ✅ | v1.0.0+ | |
| DescribeEgressOnlyInternetGateways | ✅ | ✅ | v1.0.0+ | |
| DeleteEgressOnlyInternetGateway | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Elastic IPs

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| AllocateAddress | ✅ | ✅ | v1.0.0+ | |
| ReleaseAddress | ✅ | ✅ | v1.0.0+ | |
| AssociateAddress | ✅ | ✅ | v1.0.0+ | |
| DisassociateAddress | ✅ | ✅ | v1.0.0+ | |
| DescribeAddresses | ✅ | ✅ | v1.0.0+ | |
| **DescribeAddressesAttribute** | ❌ | ✅ | — | **Missing** — `InvalidAction` khi Terraform refresh `aws_eip` |

---

## EC2 — Network Interfaces

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateNetworkInterface | ✅ | ✅ | v1.0.0+ | |
| DeleteNetworkInterface | ✅ | ✅ | v1.0.0+ | |
| DescribeNetworkInterfaces | ✅ | ✅ | v1.0.0+ | |
| AttachNetworkInterface | ✅ | ✅ | v1.0.0+ | |
| DetachNetworkInterface | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Key Pairs

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateKeyPair | ✅ | ✅ | v1.0.0+ | |
| DeleteKeyPair | ✅ | ✅ | v1.0.0+ | |
| DescribeKeyPairs | ✅ | ✅ | v1.0.0+ | |
| ImportKeyPair | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Network ACLs & Flow Logs

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateNetworkAcl | ✅ | ✅ | v1.0.0+ | |
| DescribeNetworkAcls | ✅ | ✅ | v1.0.0+ | |
| DeleteNetworkAcl | ✅ | ✅ | v1.0.0+ | |
| CreateNetworkAclEntry | ✅ | ✅ | v1.0.0+ | |
| DeleteNetworkAclEntry | ✅ | ✅ | v1.0.0+ | |
| ReplaceNetworkAclEntry | ✅ | ✅ | v1.0.0+ | |
| ReplaceNetworkAclAssociation | ✅ | ✅ | v1.0.0+ | |
| CreateFlowLogs | ✅ | ✅ | v1.0.0+ | |
| DescribeFlowLogs | ✅ | ✅ | v1.0.0+ | |
| DeleteFlowLogs | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — DHCP

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateDhcpOptions | ✅ | ✅ | v1.0.0+ | |
| AssociateDhcpOptions | ✅ | ✅ | v1.0.0+ | |
| DescribeDhcpOptions | ✅ | ✅ | v1.0.0+ | |
| DeleteDhcpOptions | ✅ | ✅ | v1.0.0+ | |

---

## EBS

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateVolume | ✅ | ✅ | v1.0.0+ | |
| DeleteVolume | ✅ | ✅ | v1.0.0+ | |
| DescribeVolumes | ✅ | ✅ | v1.0.0+ | |
| DescribeVolumeStatus | ✅ | ✅ | v1.0.0+ | |
| AttachVolume | ✅ | ✅ | v1.0.0+ | Cập nhật volume state khi attach/detach |
| DetachVolume | ✅ | ✅ | v1.0.0+ | |
| ModifyVolume | ✅ | ✅ | v1.0.0+ | |
| DescribeVolumesModifications | ✅ | ✅ | v1.0.0+ | |
| CreateSnapshot | ✅ | ✅ | v1.0.0+ | MiniStack: stored as completed immediately |
| DeleteSnapshot | ✅ | ✅ | v1.0.0+ | |
| DescribeSnapshots | ✅ | ✅ | v1.0.0+ | |
| CopySnapshot | ✅ | ✅ | v1.0.0+ | |
| ModifySnapshotAttribute | ✅ | ✅ | v1.0.0+ | |

---

## Known Missing APIs — cần patch thủ công

| API | Service | MiniStack | LocalStack Pro | Trigger | Workaround |
|---|---|---|---|---|---|
| `DescribeVpcAttribute` | EC2 | ❌ | ✅ | Terraform refresh `aws_vpc` (provider ≥ 5.x) | Patch `ec2.py` hoặc pin provider `~> 4.67` |
| `DescribeAddressesAttribute` | EC2 | ❌ | ✅ | Terraform refresh `aws_eip` (provider ≥ 5.x) | Patch `ec2.py` hoặc tránh dùng `aws_eip` |

---

## Detailed Limitations and Workarounds

### Environment Context
| Emulator | Image | Port | Environment |
|----------|-------|------|-------------|
| MiniStack | `nahuelnucera/ministack:latest` | `:4566` | `environments/dev` |
| LocalStack Pro | `localstack/localstack-pro:latest` | `:4567` | `environments/prod` |

### Transit Gateway Cross-Region Peering Hang

**Resource:** `aws_ec2_transit_gateway_peering_attachment_accepter`
**Observed in:** `environments/prod` on LocalStack Pro

**Symptom**  
`terraform apply` hangs at: `module.transit_gateway.aws_ec2_transit_gateway_peering_attachment_accepter.cross_region: Still creating...` and never completes.

**Root Cause**  
1. Terraform provider calls `AcceptTransitGatewayPeeringAttachment` -- LocalStack accepts it and returns `State: available`.
2. Provider then enters an **internal waiter** that polls `DescribeTransitGatewayPeeringAttachments` waiting for state `available`.
3. During a concurrent `terraform apply`, the Describe call does not return the expected `available` state from the provider's waiter perspective.
4. The resource has **no configurable `timeouts {}` block** -- the waiter runs indefinitely.

*Workaround*: Disable cross-region peering in LocalStack environments using variables.

```hcl
# In environments/prod/terraform.tfvars
enable_tgw_cross_region_peering = false
```

### MiniStack Missing EC2 APIs

**Observed in:** `environments/dev` on MiniStack

**Symptom**  
`terraform apply` fails with `Unknown EC2 action: DescribeVpcAttribute` or `DescribeAddressesAttribute`.

**Root Cause**  
MiniStack does not implement these API actions called by the Terraform AWS provider during resource refresh.

*Workaround*: Use `terraform destroy -refresh=false -lock=false` to clean up partial state if apply fails, and pin the `hashicorp/aws` provider to `4.x`.

### Recovery Procedures

**After a hung `terraform apply` (LocalStack)**
```bash
# 1. Kill the hung process
kill <PID>

# 2. Kill any lingering provider processes
ps aux | grep tfprovider | grep -v grep | awk '{print $2}' | xargs -r kill -9

# 3. Remove stale lock file
rm -f environments/prod/.terraform.tfstate.lock.info

# 4. Destroy with lock bypass
terraform -chdir=environments/prod destroy -auto-approve -lock=false
```

**After a failed MiniStack apply**
```bash
terraform -chdir=environments/dev destroy -auto-approve -refresh=false -lock=false
```
---
