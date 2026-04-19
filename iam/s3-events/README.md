# Case Study 4 — S3 Event → SNS/SQS Fan-out (Event-Driven)

> **Folder:** `iam/s3-events/` · **Resources:** 20 · **Account:** 888888888888 · **Region:** ap-southeast-1

## Scenario

File upload → S3 event notification → SNS fan-out → 2 SQS queues. EKS pods consume: **processor (IRSA)** + **archiver (Pod Identity)**. Demonstrates 4-layer IAM policy chain in event-driven architecture.

---

## Architecture

```mermaid
flowchart TD
  subgraph Upload["File Upload"]
    User["User / CI Pipeline"]
  end

  subgraph S3Layer["Layer 1: S3 → SNS (Topic Policy)"]
    S3["S3 Bucket\nfile-uploads\nEvent: ObjectCreated:*\n(.csv, .json)"]
    SNS["SNS Topic\nfile-events\nPolicy: allow s3.amazonaws.com"]
  end

  subgraph SQSLayer["Layer 2: SNS → SQS (Queue Policy)"]
    SQS1["SQS: file-processor\n+ DLQ\nPolicy: allow sns.amazonaws.com"]
    SQS2["SQS: file-archiver\n+ DLQ\nPolicy: allow sns.amazonaws.com"]
  end

  subgraph EKSLayer["Layer 3-4: IAM → SQS + S3 (Permission Policy)"]
    Pod1["EKS Pod: processor\nPattern: IRSA\nSA: file-processor"]
    Pod2["EKS Pod: archiver\nPattern: Pod Identity\nSA: file-archiver"]
  end

  User -->|"PutObject"| S3
  S3 -->|"S3 Event\nNotification"| SNS
  SNS -->|"Fan-out"| SQS1
  SNS -->|"Fan-out"| SQS2
  SQS1 -->|"sqs:ReceiveMessage"| Pod1
  SQS2 -->|"sqs:ReceiveMessage"| Pod2
  Pod1 -.->|"s3:GetObject\n(fetch file)"| S3
  Pod2 -.->|"s3:GetObject +\ns3:PutObject\n(archive)"| S3

  classDef s3 fill:#fff2cc,stroke:#d6b656,color:#000
  classDef sns fill:#f8cecc,stroke:#b85450,color:#000
  classDef sqs fill:#dae8fc,stroke:#6c8ebf,color:#000
  classDef irsa fill:#d1ecf1,stroke:#0c5460,color:#000
  classDef podid fill:#d4edda,stroke:#28a745,color:#000

  class S3 s3
  class SNS sns
  class SQS1,SQS2 sqs
  class Pod1 irsa
  class Pod2 podid
```

---

## Policy Chain Analysis (4 layers)

| Layer | Resource | Policy Type | Principal | Action | Condition |
|:-----:|----------|------------|-----------|--------|-----------|
| **1** | SNS Topic | Topic Policy (resource) | `s3.amazonaws.com` | `sns:Publish` | `ArnLike: aws:SourceArn = bucket ARN` |
| **2a** | SQS Processor | Queue Policy (resource) | `sns.amazonaws.com` | `sqs:SendMessage` | `ArnEquals: aws:SourceArn = topic ARN` |
| **2b** | SQS Archiver | Queue Policy (resource) | `sns.amazonaws.com` | `sqs:SendMessage` | `ArnEquals: aws:SourceArn = topic ARN` |
| **3a** | Processor Role | Trust (IRSA) | `Federated: OIDC ARN` | `sts:AssumeRoleWithWebIdentity` | `:sub` + `:aud` |
| **3b** | Archiver Role | Trust (Pod Identity) | `pods.eks.amazonaws.com` | `sts:AssumeRole, sts:TagSession` | — |
| **4a** | Processor Role | Permission | — | `sqs:ReceiveMessage` + `s3:GetObject` | Resource ARN scoped |
| **4b** | Archiver Role | Permission | — | `sqs:ReceiveMessage` + `s3:GetObject/PutObject` | Resource ARN scoped |

### Layer-by-Layer — Tại sao cần?

**Layer 1 — S3 → SNS:** S3 notification cần SNS topic policy cho phép `s3.amazonaws.com` publish. Condition `ArnLike` lock đúng bucket cụ thể.

**Layer 2 — SNS → SQS:** Mỗi SQS queue cần queue policy cho phép `sns.amazonaws.com` send message. Condition `ArnEquals` lock đúng topic cụ thể.

**Layer 3 — Pod → Role:** Processor dùng IRSA (`:sub` + `:aud`), Archiver dùng Pod Identity (`pods.eks.amazonaws.com`).

**Layer 4 — Role → Resources:** Processor chỉ đọc SQS + S3 (`GetObject`). Archiver đọc SQS + đọc/ghi S3 (`GetObject` + `PutObject` cho archive).

---

## Event Flow

```mermaid
sequenceDiagram
    participant User
    participant S3
    participant SNS
    participant SQS_P as SQS (Processor)
    participant SQS_A as SQS (Archiver)
    participant Pod_P as Processor Pod
    participant Pod_A as Archiver Pod

    User->>S3: PutObject (file.csv)
    S3->>SNS: S3 Event Notification
    SNS->>SQS_P: Fan-out (message 1)
    SNS->>SQS_A: Fan-out (message 2)

    Pod_P->>SQS_P: ReceiveMessage (long-poll 20s)
    SQS_P-->>Pod_P: Message (S3 key, bucket)
    Pod_P->>S3: GetObject (fetch file)
    S3-->>Pod_P: File content
    Pod_P->>Pod_P: Process file
    Pod_P->>SQS_P: DeleteMessage

    Pod_A->>SQS_A: ReceiveMessage
    SQS_A-->>Pod_A: Message
    Pod_A->>S3: GetObject + PutObject (archive copy)
    Pod_A->>SQS_A: DeleteMessage
```

---

## So sánh Processor (IRSA) vs Archiver (Pod Identity)

| Tiêu chí | Processor (IRSA) | Archiver (Pod Identity) |
|----------|------------------|------------------------|
| **Trust** | Federated OIDC, `:sub` = `file-processor` | `pods.eks.amazonaws.com` |
| **SQS access** | `sqs:ReceiveMessage` processor queue only | `sqs:ReceiveMessage` archiver queue only |
| **S3 access** | `s3:GetObject` (read only) | `s3:GetObject + PutObject` (read + archive) |
| **Audit trail** | Role name in CloudTrail | Role + namespace + SA tags |
| **DLQ monitoring** | Processor DLQ only | Archiver DLQ only |
| **Scale to N queues** | 1 role per queue (or wildcard) | 1 role per queue + ABAC possible |

---

## DLQ Strategy

```
file-processor → fail 3x → file-processor-dlq (14 days retention)
file-archiver  → fail 3x → file-archiver-dlq  (14 days retention)
```

| Config | Value | Why |
|--------|-------|-----|
| `maxReceiveCount` | 3 | 3 attempts trước khi vào DLQ |
| `message_retention_seconds` | 1,209,600 (14 days) | DLQ giữ 14 ngày để investigate |
| `visibility_timeout_seconds` | 300 (5 min) | Cho processor đủ thời gian xử lý |
| `receive_wait_time_seconds` | 20 | Long-polling giảm empty receives |

---

## Validate

```bash
cd iam/s3-events
terraform init -input=false
terraform apply -auto-approve   # 20 resources
terraform output
```
