# MiniStack vs LocalStack — Service Comparison

> MiniStack: **v1.1.36**
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
| S3 disk persistence | ✅ | ✅ | v1.0.0+ | MiniStack: `S3_PERSIST=1` — LocalStack Pro: enabled by default |
| S3 Control ListTagsForResource | ✅ | ✅ | v1.1.14 | MiniStack fix: returns correct tags instead of empty list; routing fixed in v1.1.18 |

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
| IAM policy enforcement | ❌ | ✅ | — | MiniStack does not enforce IAM policies like real AWS |

---

## STS

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| GetCallerIdentity | ✅ | ✅ | v1.0.0+ | |
| AssumeRole | ✅ | ✅ | v1.0.0+ | |
| GetSessionToken | ✅ | ✅ | v1.0.0+ | |
| AssumeRoleWithWebIdentity | ✅ | ✅ | v1.0.0+ | |

---

## WAF v2

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateWebACL | ✅ | ✅ | v1.1.17+ | WAFv2 core APIs supported
| GetWebACL | ✅ | ✅ | v1.1.17+ | |
| UpdateWebACL | ✅ | ✅ | v1.1.17+ | `LockToken` required
| DeleteWebACL | ✅ | ✅ | v1.1.17+ | `LockToken` required
| ListWebACLs | ✅ | ✅ | v1.1.17+ | |
| AssociateWebACL | ✅ | ✅ | v1.1.17+ | |
| DisassociateWebACL | ✅ | ✅ | v1.1.17+ | |
| GetWebACLForResource | ✅ | ✅ | v1.1.17+ | |
| ListResourcesForWebACL | ✅ | ✅ | v1.1.17+ | |
| CreateIPSet | ✅ | ✅ | v1.1.17+ | |
| GetIPSet | ✅ | ✅ | v1.1.17+ | |
| UpdateIPSet | ✅ | ✅ | v1.1.17+ | `LockToken` required
| DeleteIPSet | ✅ | ✅ | v1.1.17+ | `LockToken` required
| ListIPSets | ✅ | ✅ | v1.1.17+ | |
| CreateRuleGroup | ✅ | ✅ | v1.1.17+ | |
| GetRuleGroup | ✅ | ✅ | v1.1.17+ | |
| UpdateRuleGroup | ✅ | ✅ | v1.1.17+ | `LockToken` required
| DeleteRuleGroup | ✅ | ✅ | v1.1.17+ | `LockToken` required
| ListRuleGroups | ✅ | ✅ | v1.1.17+ | |
| TagResource | ✅ | ✅ | v1.1.17+ | |
| UntagResource | ✅ | ✅ | v1.1.17+ | |
| ListTagsForResource | ✅ | ✅ | v1.1.17+ | |
| CheckCapacity | ✅ | ✅ | v1.1.17+ | |
| DescribeManagedRuleGroup | ✅ | ✅ | v1.1.17+ | |

---

## EC2 — Instances & Images

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| RunInstances | ✅ | ✅ | v1.0.0+ | MiniStack: in-memory only, no real VMs |
| DescribeInstances | ✅ | ✅ | v1.0.0+ | |
| TerminateInstances | ✅ | ✅ | v1.0.0+ | |
| StopInstances | ✅ | ✅ | v1.0.0+ | |
| StartInstances | ✅ | ✅ | v1.0.0+ | |
| RebootInstances | ✅ | ✅ | v1.0.0+ | |
| DescribeImages | ✅ | ✅ | v1.0.0+ | |
| DescribeInstanceAttribute | ✅ | ✅ | v1.1.14 | Fix for Terraform AWS Provider ≥ 6.0.0; supports instanceType, userData, blockDeviceMapping, groupSet, etc. |
| DescribeInstanceTypes | ✅ | ✅ | v1.1.14 | 12 instance families: t2, t3, m5, c5, r5, p3, etc. |
| DescribeInstanceCreditSpecifications | ✅ | ✅ | v1.1.18 | Terraform v6 provider compatible stub for CPU credits |
| DescribeInstanceMaintenanceOptions | ✅ | ✅ | v1.1.18 | Terraform v6 provider compatibility stub |
| DescribeInstanceAutoRecoveryAttribute | ✅ | ✅ | v1.1.18 | Terraform v6 provider compatibility stub |
| ModifyInstanceMaintenanceOptions | ✅ | ✅ | v1.1.18 | Terraform v6 provider compatibility stub |
| DescribeInstanceTopology | ✅ | ✅ | v1.1.18 | Terraform v6 provider compatibility stub |
| DescribeSpotInstanceRequests | ✅ | ✅ | v1.1.18 | Terraform v6 provider compatibility stub |
| DescribeCapacityReservations | ✅ | ✅ | v1.1.18 | Terraform v6 provider compatibility stub |
| DescribeAvailabilityZones | ✅ | ✅ | v1.0.0+ | |
| DescribeTags / CreateTags / DeleteTags | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Security Groups

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateSecurityGroup | ✅ | ✅ | v1.0.0+ | Default SG always present; non-default SGs include allow-all egress rule (fixed in v1.1.18) |
| DeleteSecurityGroup | ✅ | ✅ | v1.0.0+ | |
| DescribeSecurityGroups | ✅ | ✅ | v1.0.0+ | vpc-id/group-name filters supported (v1.1.35) |
| AuthorizeSecurityGroupIngress | ✅ | ✅ | v1.0.0+ | Rules stored, not enforced on either emulator; deduplication fixed in v1.1.18 |
| RevokeSecurityGroupIngress | ✅ | ✅ | v1.0.0+ | |
| AuthorizeSecurityGroupEgress | ✅ | ✅ | v1.0.0+ | Rules stored, not enforced on either emulator; deduplication fixed in v1.1.18 |
| RevokeSecurityGroupEgress | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — VPC & Subnets

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateVpc | ✅ | ✅ | v1.0.0+ | Default VPC always present; per-VPC default resources (route table, NACL, SG) created in v1.1.35 |
| DeleteVpc | ✅ | ✅ | v1.0.0+ | |
| DescribeVpcs | ✅ | ✅ | v1.0.0+ | |
| ModifyVpcAttribute | ✅ | ✅ | v1.0.0+ | Persists EnableDnsSupport / EnableDnsHostnames in state |
| **DescribeVpcAttribute** | ✅ | ✅ | v1.1.32+ | **FIXED** — Now returns EnableDnsSupport, EnableDnsHostnames, EnableNetworkAddressUsageMetrics |
| **DescribeVpcClassicLink** | ❌ | ✅ | — | **Missing** — required for Terraform `aws_vpc` refresh (`ClassicLinkEnabled`) with provider 4.67+ |
| CreateSubnet | ✅ | ✅ | v1.0.0+ | Default subnet always present |
| DeleteSubnet | ✅ | ✅ | v1.0.0+ | |
| DescribeSubnets | ✅ | ✅ | v1.0.0+ | |
| ModifySubnetAttribute | ✅ | ✅ | v1.0.0+ | |
| CreateVpcEndpoint | ✅ | ✅ | v1.0.0+ | |
| DeleteVpcEndpoints | ✅ | ✅ | v1.0.0+ | |
| DescribeVpcEndpoints | ✅ | ✅ | v1.0.0+ | |
| ModifyVpcEndpoint | ✅ | ✅ | v1.1.36+ | Add/remove route tables, subnets, and policy on existing VPC endpoints |
| CreateVpcPeeringConnection | ✅ | ✅ | v1.0.0+ | |
| AcceptVpcPeeringConnection | ✅ | ✅ | v1.0.0+ | |
| DescribeVpcPeeringConnections | ✅ | ✅ | v1.0.0+ | Region field in requesterVpcInfo/accepterVpcInfo fixed in v1.1.18 |
| DeleteVpcPeeringConnection | ✅ | ✅ | v1.0.0+ | |

---

## EC2 — Internet Gateway & Routing

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateInternetGateway | ✅ | ✅ | v1.0.0+ | Default IGW always present |
| DeleteInternetGateway | ✅ | ✅ | v1.0.0+ | |
| DescribeInternetGateways | ✅ | ✅ | v1.0.0+ | |
| AttachInternetGateway | ✅ | ✅ | v1.0.0+ | |
| DetachInternetGateway | ✅ | ✅ | v1.0.0+ | |
| CreateRouteTable | ✅ | ✅ | v1.0.0+ | Default route table always present |
| DeleteRouteTable | ✅ | ✅ | v1.0.0+ | |
| DescribeRouteTables | ✅ | ✅ | v1.0.0+ | association.main, association.route-table-association-id, association.subnet-id, vpc-id filters supported (v1.1.34+) |
| AssociateRouteTable | ✅ | ✅ | v1.0.0+ | |
| DisassociateRouteTable | ✅ | ✅ | v1.0.0+ | |
| ReplaceRouteTableAssociation | ✅ | ✅ | v1.1.36+ | Moves subnet association from one route table to another |
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
| **DescribeAddressesAttribute** | ❌ | ✅ | — | **Missing** — `InvalidAction` on Terraform refresh of `aws_eip` |

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
| DescribeNetworkAcls | ✅ | ✅ | v1.0.0+ | vpc-id + default=true filter supported (v1.1.35) |
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
| AttachVolume | ✅ | ✅ | v1.0.0+ | Updates volume state on attach/detach |
| DetachVolume | ✅ | ✅ | v1.0.0+ | |
| ModifyVolume | ✅ | ✅ | v1.0.0+ | |
| DescribeVolumesModifications | ✅ | ✅ | v1.0.0+ | |
| CreateSnapshot | ✅ | ✅ | v1.0.0+ | MiniStack: stored as completed immediately |
| DeleteSnapshot | ✅ | ✅ | v1.0.0+ | |
| DescribeSnapshots | ✅ | ✅ | v1.0.0+ | |
| CopySnapshot | ✅ | ✅ | v1.0.0+ | |
| ModifySnapshotAttribute | ✅ | ✅ | v1.0.0+ | |

---

## Lambda

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateFunction | ✅ | ✅ | v1.1.18+ | Supports ZipFile, S3Bucket/S3Key code sources |
| UpdateFunctionCode | ✅ | ✅ | v1.1.18+ | Supports ZipFile, S3Bucket/S3Key code sources |
| UpdateFunctionConfiguration | ✅ | ✅ | v1.1.18+ | |
| GetFunction | ✅ | ✅ | v1.1.18+ | |
| ListFunctions | ✅ | ✅ | v1.1.18+ | |
| DeleteFunction | ✅ | ✅ | v1.1.18+ | |
| Invoke | ✅ | ✅ | v1.1.18+ | |
| PublishVersion | ✅ | ✅ | v1.1.18+ | Creates immutable numbered versions |
| ListVersionsByFunction | ✅ | ✅ | v1.1.18+ | |
| CreateFunctionUrlConfig | ✅ | ✅ | v1.1.18+ | |
| GetFunctionUrlConfig | ✅ | ✅ | v1.1.18+ | |
| DeleteFunctionUrlConfig | ✅ | ✅ | v1.1.18+ | |
| CreateEventSourceMapping | ✅ | ✅ | v1.1.18+ | Supports SQS and Kinesis streams |
| GetEventSourceMapping | ✅ | ✅ | v1.1.18+ | |
| ListEventSourceMappings | ✅ | ✅ | v1.1.18+ | |
| UpdateEventSourceMapping | ✅ | ✅ | v1.1.18+ | |
| DeleteEventSourceMapping | ✅ | ✅ | v1.1.18+ | |
| Node.js runtime support | ✅ | ✅ | v1.1.18+ | Warm worker pool with async/await, Promise, callback handlers |
| Python runtime support | ✅ | ✅ | v1.0.0+ | Warm worker pool |
| Provided runtime support | ✅ | ✅ | v1.1.36+ | provided.al2023, provided.al2 runtimes via Docker with AWS Lambda RIE |

---

## EC2 — Prefix Lists & Managed Prefix Lists

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| DescribePrefixLists | ✅ | ✅ | v1.1.36+ | Returns AWS service prefix lists (S3, DynamoDB) and user-managed |
| CreateManagedPrefixList | ✅ | ✅ | v1.1.36+ | |
| DescribeManagedPrefixLists | ✅ | ✅ | v1.1.36+ | |
| GetManagedPrefixListEntries | ✅ | ✅ | v1.1.36+ | |
| ModifyManagedPrefixList | ✅ | ✅ | v1.1.36+ | |
| DeleteManagedPrefixList | ✅ | ✅ | v1.1.36+ | |

---

## EC2 — VPN Gateways & Customer Gateways

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateVpnGateway | ✅ | ✅ | v1.1.36+ | |
| DescribeVpnGateways | ✅ | ✅ | v1.1.36+ | Includes attachment state tracking |
| AttachVpnGateway | ✅ | ✅ | v1.1.36+ | |
| DetachVpnGateway | ✅ | ✅ | v1.1.36+ | |
| DeleteVpnGateway | ✅ | ✅ | v1.1.36+ | |
| EnableVgwRoutePropagation | ✅ | ✅ | v1.1.36+ | |
| DisableVgwRoutePropagation | ✅ | ✅ | v1.1.36+ | |
| CreateCustomerGateway | ✅ | ✅ | v1.1.36+ | |
| DescribeCustomerGateways | ✅ | ✅ | v1.1.36+ | |
| DeleteCustomerGateway | ✅ | ✅ | v1.1.36+ | |

---

## CloudFront

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateDistribution | ✅ | ✅ | v1.1.26+ | ETag-based concurrency control |
| GetDistribution | ✅ | ✅ | v1.1.26+ | |
| GetDistributionConfig | ✅ | ✅ | v1.1.26+ | |
| ListDistributions | ✅ | ✅ | v1.1.26+ | |
| UpdateDistribution | ✅ | ✅ | v1.1.26+ | |
| DeleteDistribution | ✅ | ✅ | v1.1.26+ | |
| CreateInvalidation | ✅ | ✅ | v1.1.26+ | |
| ListInvalidations | ✅ | ✅ | v1.1.26+ | |
| GetInvalidation | ✅ | ✅ | v1.1.26+ | |

---

## ECR

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateRepository | ✅ | ✅ | v1.1.26+ | |
| DescribeRepositories | ✅ | ✅ | v1.1.26+ | |
| DeleteRepository | ✅ | ✅ | v1.1.26+ | |
| PutImage | ✅ | ✅ | v1.1.26+ | |
| BatchGetImage | ✅ | ✅ | v1.1.26+ | |
| BatchDeleteImage | ✅ | ✅ | v1.1.26+ | |
| ListImages | ✅ | ✅ | v1.1.26+ | |
| DescribeImages | ✅ | ✅ | v1.1.26+ | |
| GetAuthorizationToken | ✅ | ✅ | v1.1.26+ | |
| Lifecycle policies | ✅ | ✅ | v1.1.26+ | |
| Repository policies | ✅ | ✅ | v1.1.26+ | |
| Tags | ✅ | ✅ | v1.1.26+ | |
| Layer upload flow | ✅ | ✅ | v1.1.26+ | |

---

## AppSync

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateGraphQLApi | ✅ | ✅ | v1.1.32+ | REST/JSON API under /v1/apis |
| GetGraphQLApi | ✅ | ✅ | v1.1.32+ | |
| ListGraphQLApis | ✅ | ✅ | v1.1.32+ | |
| UpdateGraphQLApi | ✅ | ✅ | v1.1.32+ | |
| DeleteGraphQLApi | ✅ | ✅ | v1.1.32+ | |
| CreateApiKey | ✅ | ✅ | v1.1.32+ | |
| ListApiKeys | ✅ | ✅ | v1.1.32+ | |
| DeleteApiKey | ✅ | ✅ | v1.1.32+ | |
| CreateDataSource | ✅ | ✅ | v1.1.32+ | |
| GetDataSource | ✅ | ✅ | v1.1.32+ | |
| ListDataSources | ✅ | ✅ | v1.1.32+ | |
| DeleteDataSource | ✅ | ✅ | v1.1.32+ | |
| CreateResolver | ✅ | ✅ | v1.1.32+ | |
| GetResolver | ✅ | ✅ | v1.1.32+ | |
| ListResolvers | ✅ | ✅ | v1.1.32+ | |
| DeleteResolver | ✅ | ✅ | v1.1.32+ | |
| CreateType | ✅ | ✅ | v1.1.32+ | |
| ListTypes | ✅ | ✅ | v1.1.32+ | |
| GetType | ✅ | ✅ | v1.1.32+ | |
| TagResource | ✅ | ✅ | v1.1.32+ | |
| UntagResource | ✅ | ✅ | v1.1.32+ | |
| ListTagsForResource | ✅ | ✅ | v1.1.32+ | |
| GraphQL data plane | ✅ | ✅ | v1.1.33+ | POST /v1/apis/{apiId}/graphql executes queries and mutations |

---

## Cognito

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateUserPool | ✅ | ✅ | v1.1.32+ | |
| GetUserPool | ✅ | ✅ | v1.1.32+ | |
| ListUserPools | ✅ | ✅ | v1.1.32+ | |
| UpdateUserPool | ✅ | ✅ | v1.1.32+ | |
| DeleteUserPool | ✅ | ✅ | v1.1.32+ | |
| CreateUserPoolClient | ✅ | ✅ | v1.1.32+ | |
| GetUserPoolClient | ✅ | ✅ | v1.1.32+ | |
| ListUserPoolClients | ✅ | ✅ | v1.1.32+ | |
| UpdateUserPoolClient | ✅ | ✅ | v1.1.32+ | |
| DeleteUserPoolClient | ✅ | ✅ | v1.1.32+ | |
| CreateIdentityPool | ✅ | ✅ | v1.1.32+ | |
| GetIdentityPool | ✅ | ✅ | v1.1.32+ | |
| ListIdentityPools | ✅ | ✅ | v1.1.32+ | |
| UpdateIdentityPool | ✅ | ✅ | v1.1.32+ | |
| DeleteIdentityPool | ✅ | ✅ | v1.1.32+ | |
| CreateUserPoolDomain | ✅ | ✅ | v1.1.32+ | |
| GetUserPoolDomain | ✅ | ✅ | v1.1.32+ | |
| DeleteUserPoolDomain | ✅ | ✅ | v1.1.32+ | |
| JWKS/OIDC endpoints | ✅ | ✅ | v1.1.32+ | /.well-known/jwks.json, /.well-known/openid-configuration |

---

## KMS

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateKey | ✅ | ✅ | v1.1.26+ | |
| DescribeKey | ✅ | ✅ | v1.1.26+ | |
| ListKeys | ✅ | ✅ | v1.1.26+ | |
| ScheduleKeyDeletion | ✅ | ✅ | v1.1.36+ | |
| CancelKeyDeletion | ✅ | ✅ | v1.1.36+ | |
| EnableKey | ✅ | ✅ | v1.1.36+ | |
| DisableKey | ✅ | ✅ | v1.1.36+ | |
| EnableKeyRotation | ✅ | ✅ | v1.1.36+ | |
| DisableKeyRotation | ✅ | ✅ | v1.1.36+ | |
| GetKeyRotationStatus | ✅ | ✅ | v1.1.36+ | |
| GetKeyPolicy | ✅ | ✅ | v1.1.36+ | |
| PutKeyPolicy | ✅ | ✅ | v1.1.36+ | |
| ListKeyPolicies | ✅ | ✅ | v1.1.36+ | |
| TagResource | ✅ | ✅ | v1.1.36+ | |
| UntagResource | ✅ | ✅ | v1.1.36+ | |
| ListResourceTags | ✅ | ✅ | v1.1.36+ | |
| Encrypt | ✅ | ✅ | v1.1.26+ | |
| Decrypt | ✅ | ✅ | v1.1.26+ | |
| GenerateDataKey | ✅ | ✅ | v1.1.26+ | |
| GenerateDataKeyWithoutPlaintext | ✅ | ✅ | v1.1.26+ | |
| Sign | ✅ | ✅ | v1.1.36+ | RSA Sign/Verify with cryptography package |
| Verify | ✅ | ✅ | v1.1.36+ | |
| GetPublicKey | ✅ | ✅ | v1.1.36+ | |

---

## Route53

| Operation | MiniStack | LocalStack Pro | MiniStack Version | Notes |
|---|---|---|---|---|
| CreateHostedZone | ✅ | ✅ | v1.1.26+ | |
| GetHostedZone | ✅ | ✅ | v1.1.26+ | |
| ListHostedZones | ✅ | ✅ | v1.1.26+ | |
| DeleteHostedZone | ✅ | ✅ | v1.1.26+ | |
| ChangeResourceRecordSets | ✅ | ✅ | v1.1.26+ | |
| ListResourceRecordSets | ✅ | ✅ | v1.1.26+ | Fixed ordering and pagination in v1.1.25 |
| GetChange | ✅ | ✅ | v1.1.26+ | |
| GetHealthCheck | ✅ | ✅ | v1.1.26+ | |
| ListHealthChecks | ✅ | ✅ | v1.1.26+ | |
| CreateHealthCheck | ✅ | ✅ | v1.1.26+ | |
| DeleteHealthCheck | ✅ | ✅ | v1.1.26+ | |
| UpdateHealthCheck | ✅ | ✅ | v1.1.26+ | |

---

## Known Missing APIs — patch MiniStack or pin provider

The following APIs are **missing or incomplete** on MiniStack at the time of writing; **LocalStack Pro** usually has them. Per-operation detail is in the EC2 sections above (e.g. `DescribeVpcAttribute` is listed under **EC2 — VPC & Subnets** from MiniStack **v1.1.32+**).

| API | Service | MiniStack | LocalStack Pro | Trigger | Workaround |
|---|---|---|---|---|---|
| `DescribeAddressesAttribute` | EC2 | ❌ | ✅ | Terraform refresh of `aws_eip` (domain attributes / newer provider behavior) | Keep `hashicorp/aws` **>= 4.0, < 4.67** + commit `.terraform.lock.hcl`; or avoid `aws_eip` on `dev`; patch MiniStack `ec2.py` |
| `DescribeVpcClassicLink` | EC2 | ❌ | ✅ | Terraform refresh of `aws_vpc` (`ClassicLinkEnabled`) — **hashicorp/aws 4.67+** | Commit lockfile with provider **≤ 4.66.x**, or `terraform destroy -refresh=false`; or patch MiniStack |

*CLI check (MiniStack endpoint): `aws ec2 describe-addresses-attribute ... --endpoint-url=http://localhost:4566` returns `InvalidAction` while the API is missing. For `DescribeVpcAttribute`, use MiniStack image **≥ v1.1.32** (`docker pull nahuelnucera/ministack:latest`).*

---

## Detailed Limitations and Workarounds

### Environment Context
| Emulator | Image | Port | Environment |
|----------|-------|------|-------------|
| MiniStack | `nahuelnucera/ministack:latest` | `:4566` | `environments/dev` |
| LocalStack Pro | `localstack/localstack-pro:latest` | `:4567` | `environments/prod` |

### State Persistence (v1.1.25+)
MiniStack now supports state persistence for 20 services when `PERSIST_STATE=1`:
- **v1.1.25**: SQS, SNS, SSM, SecretsManager, IAM, DynamoDB, KMS, EventBridge, CloudWatch Logs, Kinesis
- **v1.1.26**: Lambda (config + code_zip), EC2, Route53, Cognito, ECR, CloudWatch Metrics, S3 metadata, RDS, ECS, ElastiCache
- State is saved on shutdown and restored on startup via atomic JSON files
- S3 persistence remains separate via `S3_PERSIST=1`

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

### MiniStack vs Terraform AWS provider (EC2)

**Observed in:** `environments/dev` on MiniStack

**Symptoms**

- `Unknown EC2 action: DescribeVpcAttribute` — MiniStack image older than **v1.1.32**, or `docker pull` not run for a newer build.
- `Unknown EC2 action: DescribeAddressesAttribute` — when refreshing **`aws_eip`** (still missing on MiniStack at last check).
- `Unknown EC2 action: DescribeVpcClassicLink` — when refreshing **`aws_vpc`** with **hashicorp/aws 4.67+** (provider reads `ClassicLinkEnabled`).

**Workarounds**

1. **Pin versions**: Use `hashicorp/aws` **>= 4.0, < 4.67** and **commit** `environments/dev/.terraform.lock.hcl` and `environments/prod/.terraform.lock.hcl` so CI does not resolve a different provider build.
2. If you hit **ClassicLink** with 4.67: lock the provider in the lockfile to **4.66.x** (or another verified version) until MiniStack implements the API.
3. Clean up failed state: `terraform destroy -refresh=false -auto-approve` (after a partial apply).
4. Full API tables: **EC2** sections in this document and [MiniStack releases](https://github.com/Nahuel990/ministack/releases).
