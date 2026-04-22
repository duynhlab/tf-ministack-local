# Case Study 7 — AWS Load Balancer Controller on EKS

> **Folder:** `iam/alb-controller/` · **Lab Type:** AWS-oriented · **Scope:** Platform controller IAM

## Scenario

Platform team vận hành EKS cluster cho nhiều app teams. Ingress dùng **AWS Load Balancer Controller** để tạo ALB/NLB. Mục tiêu là tách quyền của controller khỏi node role và giải thích rõ boundary giữa **Kubernetes RBAC** và **AWS IAM**.

---

## Architecture

```mermaid
flowchart LR
  subgraph Cluster["EKS Cluster | app-prod | us-west-2"]
    Ingress["Ingress objects"]
    SA["ServiceAccount\naws-load-balancer-controller"]
    Ctrl["ALB Controller Pod"]
    RBAC["ClusterRole + RoleBinding"]
  end

  subgraph AWS["AWS APIs"]
    ELB["Elastic Load Balancing\nALB / Target Group / Listener"]
    EC2["EC2\nSecurity Group / Subnet / Tags"]
    ACM["ACM\nTLS certificates"]
    WAF["WAFv2\noptional association"]
  end

  Role["IAM Role\nalb-controller-role"]
  Id["IRSA or Pod Identity"]

  Ingress --> Ctrl
  SA --> Ctrl
  RBAC --> Ctrl
  Ctrl --> Id --> Role
  Role --> ELB
  Role --> EC2
  Role --> ACM
  Role --> WAF
```

---

## IAM Resources

| # | Resource | Mục đích |
|---|---|---|
| 1 | ServiceAccount cho controller | Identity trong Kubernetes |
| 2 | IAM Role riêng cho controller | Tách khỏi node role |
| 3 | Trust policy | Cho IRSA hoặc Pod Identity assume role |
| 4 | Permission policy | Chỉ cho phép tạo/sửa ELB, target groups, tags, SG rules cần thiết |
| 5 | Kubernetes RBAC | Cho controller đọc Ingress, Service, Endpoint, TargetGroupBinding |

---

## Policy Layers

```mermaid
flowchart TD
  L1["Layer 1\nKubernetes RBAC\nController đọc object trong cluster"]
  L2["Layer 2\nTrust policy\nController pod assume IAM role"]
  L3["Layer 3\nPermission policy\nRole gọi ELB / EC2 / ACM / WAF APIs"]
  L4["Layer 4\nResource tags / discovery\nController tìm subnet, SG, LB theo tag"]

  L1 --> L2 --> L3 --> L4
```

| Layer | Policy Type | Principal | Action | Ghi chú |
|:-----:|------------|-----------|--------|--------|
| **1** | Kubernetes RBAC | ServiceAccount | `get/list/watch` K8s resources | Không thay thế AWS IAM |
| **2** | Trust policy | OIDC / `pods.eks.amazonaws.com` | `sts:AssumeRoleWithWebIdentity` hoặc `sts:AssumeRole` | Scope chặt theo namespace + SA |
| **3** | IAM permission | Controller role | ELB/EC2/ACM/WAF actions | Tách biệt khỏi app pods |
| **4** | Discovery / tagging | AWS resources | tag-based filtering | Sai tag là controller không tìm thấy subnet/LB |

---

## Credential Flow

```mermaid
sequenceDiagram
    participant Ingress as Ingress YAML
    participant Ctrl as ALB Controller Pod
    participant Auth as IRSA / Pod Identity
    participant IAM as IAM Role
    participant AWS as ELB + EC2 APIs

    Ingress->>Ctrl: new / updated ingress
    Ctrl->>Auth: request AWS credentials
    Auth->>IAM: assume role
    IAM-->>Ctrl: temporary credentials
    Ctrl->>AWS: create/update ALB, listeners, target groups, SG rules
```

---

## Failure / Review Diagram

```mermaid
flowchart TD
  A["Ingress created but no ALB"] --> B{"Controller logs show what?"}
  B -->|"AccessDenied"| C["Check IAM permission policy"]
  B -->|"NoCredentialProviders"| D["Check IRSA / Pod Identity setup"]
  B -->|"subnet not found"| E["Check subnet discovery tags"]
  B -->|"cannot list ingress"| F["Check Kubernetes RBAC"]
```

---

## Why this matters at work

- Đây là controller xuất hiện rất nhiều trong EKS production.
- Nhiều team nhét quyền ELB/EC2 vào node role, làm blast radius quá rộng.
- Case này giúp phân biệt rất rõ:
  - `Kubernetes RBAC` quyết định controller đọc gì trong cluster
  - `AWS IAM` quyết định controller tạo gì ở AWS

---

## Review Checklist

- Controller có role riêng hay đang dùng node instance profile?
- Trust policy có khóa đúng `namespace/serviceaccount` chưa?
- Permission policy có đang rộng quá mức như `elasticloadbalancing:*` không?
- Subnet discovery có phụ thuộc tag nào?
- Có tách role của controller khỏi role của app pods không?

---

## Interview Questions

- Tại sao ALB Controller cần cả Kubernetes RBAC và AWS IAM?
- Vì sao không nên dùng node role cho controller này?
- Nếu controller tạo được ALB nhưng không attach target group, bạn kiểm tra lớp nào trước?

---

## Validate

```bash
cd iam/alb-controller
terraform init -input=false
terraform apply -auto-approve
terraform output
terraform destroy -auto-approve
```

Lab này tạo **representative VPC + ALB + target group + listener** và 2 controller roles (IRSA, Pod Identity). Nó validate IAM shape và AWS resource lifecycle, không mô phỏng controller pod thật trong EKS.
