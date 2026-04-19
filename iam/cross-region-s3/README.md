# Case Study 5 — Cross-Region S3 Replication + EKS Multi-Region Access

> **Folder:** `iam/cross-region-s3/` · **Resources:** 21 · **Account:** 999999999999 · **Regions:** ap-southeast-1 (primary) + us-west-2 (replica)

## Scenario

ML platform lưu model artifacts ở **ap-southeast-1** (primary), replicate sang **us-west-2** (DR). EKS pods ở **cả 2 regions** truy cập S3 — primary cluster **read/write**, replica cluster **read-only** (DR failover).

---

## Architecture

```mermaid
flowchart TB
  subgraph Primary["ap-southeast-1 (Primary)"]
    EKS_P["EKS Cluster\nml-cluster-primary"]
    S3_P["S3 Bucket\nml-artifacts-primary\n(source, RW)"]
    Pod_P_IRSA["Pod (IRSA)\nSA: ml-artifacts-worker"]
    Pod_P_PodId["Pod (Pod Identity)\nSA: ml-artifacts-worker"]

    Pod_P_IRSA -->|"s3:Get/Put/Delete"| S3_P
    Pod_P_PodId -->|"s3:Get/Put/Delete"| S3_P
  end

  subgraph Replica["us-west-2 (DR / Replica)"]
    EKS_R["EKS Cluster\nml-cluster-replica"]
    S3_R["S3 Bucket\nml-artifacts-replica\n(replica, RO)"]
    Pod_R_IRSA["Pod (IRSA)\nSA: ml-artifacts-worker"]
    Pod_R_PodId["Pod (Pod Identity)\nSA: ml-artifacts-worker"]

    Pod_R_IRSA -->|"s3:GetObject only"| S3_R
    Pod_R_PodId -->|"s3:GetObject only"| S3_R
  end

  CRR["S3 CRR\nReplication Role\n(s3.amazonaws.com)"]

  S3_P ==>|"Cross-Region\nReplication"| CRR
  CRR ==>|"ReplicateObject"| S3_R

  Pod_R_IRSA -.->|"DR failover:\nread from replica"| S3_R
  Pod_P_IRSA -.->|"Normal:\nRW on primary"| S3_P

  classDef primary fill:#dae8fc,stroke:#6c8ebf,color:#000
  classDef replica fill:#fff2cc,stroke:#d6b656,color:#000
  classDef crr fill:#d5e8d4,stroke:#82b366,color:#000

  class EKS_P,S3_P,Pod_P_IRSA,Pod_P_PodId primary
  class EKS_R,S3_R,Pod_R_IRSA,Pod_R_PodId replica
  class CRR crr
```

---

## IAM Roles — 3 loại

```mermaid
flowchart LR
  subgraph Roles["IAM Roles (account 999999999999)"]
    R1["Replication Role\ntrust: s3.amazonaws.com\nperm: Replicate*"]
    R2["IRSA Role\ntrust: 2x OIDC Providers\nperm: Primary RW + Replica RO"]
    R3["Pod Identity Role\ntrust: pods.eks.amazonaws.com\nperm: Primary RW + Replica RO (ABAC)"]
  end

  S3P["S3 Primary\n(source)"]
  S3R["S3 Replica\n(destination)"]

  R1 -->|"GetReplication, GetObject"| S3P
  R1 -->|"ReplicateObject, ReplicateDelete"| S3R
  R2 -->|"Get/Put/Delete"| S3P
  R2 -->|"GetObject only"| S3R
  R3 -->|"Get/Put/Delete (ABAC)"| S3P
  R3 -->|"GetObject only (ABAC)"| S3R
```

---

## Policy Analysis (4 layers)

| Layer | Policy | Trên resource nào | Chi tiết |
|:-----:|--------|-------------------|----------|
| **1 — Replication Trust** | Trust policy | Replication Role | `Service: s3.amazonaws.com` → `sts:AssumeRole` |
| **2 — Replication Permission** | IAM policy | Replication Role | Source: `GetReplicationConfiguration`, `GetObjectVersion*` · Dest: `ReplicateObject`, `ReplicateDelete` |
| **3 — App Trust** | Trust policy | IRSA / Pod Identity roles | IRSA: 2 OIDC providers (2 statements) · Pod Identity: `pods.eks.amazonaws.com` |
| **4 — App Permission** | IAM policy + Bucket policy | Roles + S3 buckets | **Primary: RW** (`Get/Put/Delete`) · **Replica: RO** (`GetObject` only) |

### Asymmetric Permissions — Tại sao?

```
Primary bucket (source of truth):
  ├── IRSA role:         s3:GetObject, PutObject, DeleteObject  ✅ RW
  └── Pod Identity role: s3:GetObject, PutObject, DeleteObject  ✅ RW (ABAC)

Replica bucket (DR failover):
  ├── IRSA role:         s3:GetObject                           ✅ RO
  └── Pod Identity role: s3:GetObject                           ✅ RO (ABAC)
```

**Lý do:**
- Replica bucket chỉ nhận data từ CRR — không cho app ghi trực tiếp để tránh conflict
- DR pods chỉ cần đọc artifacts đã replicate, không cần ghi
- Nếu primary down, DR cluster có thể đọc từ replica bucket mà không cần thay đổi IAM

---

## So sánh IRSA vs Pod Identity (Cross-Region)

| Tiêu chí | IRSA (multi-region) | Pod Identity (multi-region) |
|----------|--------------------|-----------------------------|
| **Trust policy** | 2 statements (1 per OIDC provider) | 1 statement (`pods.eks.amazonaws.com`) |
| **Thêm region/cluster mới** | Sửa trust policy: thêm OIDC statement | **Chỉ thêm Association** — trust không đổi |
| **Permission scope** | Hardcode namespace: `bucket/ml-platform/*` | ABAC: `bucket/${aws:PrincipalTag/kubernetes-namespace}/*` |
| **Primary vs Replica** | 4 statements (2 buckets × 2 action sets) | 4 statements (ABAC tự scope) |
| **Cluster migration** | Đổi OIDC URL → **sửa trust policy** | **Không sửa gì** |
| **CloudTrail** | Role name, khó biết từ cluster nào | Auto tags: cluster, namespace, SA |
| **Terraform resources** | OIDC × 2 + Role + Policy + Attachment = 5 | Role + Policy + Attachment = 3 |

### Scalability khi thêm Region thứ 3

**IRSA — phải sửa trust policy:**
```hcl
# Trust policy cần thêm statement thứ 3
data "aws_iam_policy_document" "irsa_trust" {
  statement { ... }  # primary
  statement { ... }  # replica
  statement { ... }  # ← THÊM MỚI: region thứ 3
}
# + Thêm OIDC provider resource
# + Sửa permission policy nếu thêm bucket
```

**Pod Identity — chỉ thêm Association:**
```hcl
# Trust policy KHÔNG ĐỔI
# Chỉ tạo thêm:
resource "aws_eks_pod_identity_association" "region3" {
  cluster_name    = "ml-cluster-region3"
  namespace       = "ml-platform"
  service_account = "ml-artifacts-worker"
  role_arn        = aws_iam_role.artifacts_pod_identity.arn
}
```

---

## S3 Replication IAM — Chi tiết

```mermaid
sequenceDiagram
    participant S3P as S3 Primary (source)
    participant STS as STS
    participant CRR as S3 CRR Service
    participant S3R as S3 Replica (dest)

    S3P->>STS: AssumeRole (replication role)
    STS-->>CRR: Temporary credentials

    CRR->>S3P: GetReplicationConfiguration
    CRR->>S3P: GetObjectVersionForReplication
    CRR->>S3P: GetObjectVersionAcl
    CRR->>S3P: GetObjectVersionTagging

    CRR->>S3R: ReplicateObject
    CRR->>S3R: ReplicateTags
    Note over CRR,S3R: Delete markers also replicated<br/>(ReplicateDelete)
```

**Replication role permissions (least privilege):**

| Source Bucket | Destination Bucket |
|---|---|
| `s3:GetReplicationConfiguration` | `s3:ReplicateObject` |
| `s3:ListBucket` | `s3:ReplicateDelete` |
| `s3:GetObjectVersionForReplication` | `s3:ReplicateTags` |
| `s3:GetObjectVersionAcl` | |
| `s3:GetObjectVersionTagging` | |

---

## Validate

```bash
cd iam/cross-region-s3
terraform init -input=false
terraform apply -auto-approve   # 21 resources
terraform output
```
