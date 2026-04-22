# Case Study 11 — EKS Cluster Access Entries and Break-Glass Role

> **Folder:** `iam/cluster-access/` · **Lab Type:** MiniStack runnable · **Scope:** Human access and governance

## Scenario

Team muốn bỏ dần `aws-auth` ConfigMap và quản lý quyền truy cập cluster bằng **EKS Access Entries**. Đồng thời cần giữ một **break-glass admin role** chỉ dùng trong incident, không dùng cho vận hành hàng ngày.

Case này không nói về pod access vào AWS service. Nó nói về **con người hoặc automation** vào Kubernetes API như thế nào.

---

## Architecture

```mermaid
flowchart LR
  subgraph Identity["Human / Automation identities"]
    SSO["IAM Identity Center / Federated Role"]
    DevRole["Developer Role"]
    OpsRole["Platform Ops Role"]
    Break["Break-Glass Admin Role"]
  end

  subgraph EKS["Amazon EKS"]
    Entry["Access Entry"]
    Policy["EKS Access Policy\nor Kubernetes groups"]
    API["Kubernetes API server"]
  end

  SSO --> DevRole
  SSO --> OpsRole
  Break --> Entry
  DevRole --> Entry --> Policy --> API
  OpsRole --> Entry
```

---

## Policy Layers

```mermaid
flowchart TD
  A["Layer 1\nIAM principal exists"]
  B["Layer 2\nEKS Access Entry maps principal to cluster"]
  C["Layer 3\nAccess policy or Kubernetes groups grant permissions"]
  D["Layer 4\nBreak-glass role kept separate and tightly controlled"]

  A --> B --> C --> D
```

| Layer | Policy Type | Principal | Action | Ghi chú |
|:-----:|------------|-----------|--------|--------|
| **1** | IAM federation / role trust | Human or CI identity | Assume AWS role | Nên dùng short-lived credentials |
| **2** | EKS access entry | IAM role ARN | Authenticate to cluster | Thay dần `aws-auth` |
| **3** | Access policy / RBAC | IAM role mapped to groups or access policies | Kubernetes API actions | `view`, `edit`, `admin` tách riêng |
| **4** | Break-glass controls | Admin role | emergency cluster-admin only | Không dùng hàng ngày |

---

## Access Flow

```mermaid
sequenceDiagram
    participant User as Engineer
    participant IAM as IAM / Identity Center
    participant EKS as Access Entry API
    participant API as Kubernetes API

    User->>IAM: assume developer or ops role
    IAM-->>User: short-lived AWS credentials
    User->>EKS: authenticate to cluster
    EKS-->>API: map IAM principal to access entry / groups
    API-->>User: allow kubectl actions within granted scope
```

---

## Failure / Review Diagram

```mermaid
flowchart TD
  A["kubectl access denied"] --> B{"Which layer fails?"}
  B -->|"cannot authenticate"| C["Check IAM role assumption and kubeconfig"]
  B -->|"auth ok, authz denied"| D["Check access entry or Kubernetes groups"]
  B -->|"only creator has admin"| E["Check migration off bootstrap admin"]
  B -->|"incident access missing"| F["Check break-glass role process"]
```

---

## Why this matters at work

- Nhiều cluster cũ còn lệ thuộc `aws-auth`.
- Human access và pod access thường bị trộn lẫn trong discussion, gây sai thiết kế.
- Case này buộc phân biệt:
  - ai được vào cluster
  - ai được gọi AWS service từ pod

---

## Review Checklist

- Cluster có còn phụ thuộc `aws-auth` làm nguồn auth chính không?
- Developer, platform ops, CI, break-glass có role tách riêng không?
- Cluster creator có còn permanent `cluster-admin` không?
- Break-glass role có quy trình bật/tắt và audit rõ không?
- Có dùng IAM users dài hạn thay vì federated roles không?

---

## Interview Questions

- Access Entries khác gì với `aws-auth` ConfigMap?
- Vì sao break-glass role không nên dùng cho daily operations?
- Human access vào cluster khác workload identity cho pods ở điểm nào?

---

## Validate

```bash
cd iam/cluster-access
terraform init -input=false
terraform apply -auto-approve
terraform output
terraform destroy -auto-approve
```

Mặc định lab này tạo **IAM roles + guardrail policies** cho developer, platform ops, và break-glass. `aws_eks_access_entry` được để **optional** qua biến `enable_eks_access_entries` vì support EKS control-plane trong emulator là partial.
