# VPC Enterprise Connectivity – Analysis Report

## 1. Introduction

This report analyzes three primary AWS VPC connectivity solutions for enterprise use, focusing on cross-region and multi-account scenarios. All implementations are tested on LocalStack to validate Terraform code without incurring AWS costs.

**Current context**: Single AWS Account, multi-region deployment. Planning for future multi-account migration.

---

## 2. Architecture Diagrams

### 2.1 VPC Peering (Cross-Region)

```
 ┌─────────────────────────────┐         ┌─────────────────────────────┐
 │     Region A (us-east-1)    │         │     Region B (eu-west-1)    │
 │                             │         │                             │
 │  ┌───────────────────────┐  │         │  ┌───────────────────────┐  │
 │  │  VPC: 10.0.0.0/16     │  │         │  │  VPC: 10.1.0.0/16     │  │
 │  │                       │  │         │  │                       │  │
 │  │  ┌─────────┐          │  │  VPC    │  │  ┌─────────┐          │  │
 │  │  │ Subnet  │          │◄─┼─Peering─┼──►  │ Subnet  │          │  │
 │  │  │10.0.1/24│          │  │  Conn   │  │  │10.1.1/24│          │  │
 │  │  └─────────┘          │  │         │  │  └─────────┘          │  │
 │  │  ┌─────────┐          │  │         │  │  ┌─────────┐          │  │
 │  │  │ Subnet  │          │  │         │  │  │ Subnet  │          │  │
 │  │  │10.0.2/24│          │  │         │  │  │10.1.2/24│          │  │
 │  │  └─────────┘          │  │         │  │  └─────────┘          │  │
 │  │                       │  │         │  │                       │  │
 │  │  RT: 10.1.0.0/16 →pcx │  │         │  │  RT: 10.0.0.0/16 →pcx │  │
 │  └───────────────────────┘  │         │  └───────────────────────┘  │
 └─────────────────────────────┘         └─────────────────────────────┘
```

**Key characteristics:**
- Point-to-point connection between two VPCs
- Non-transitive: if VPC-A peers with VPC-B and VPC-B peers with VPC-C, VPC-A cannot reach VPC-C through VPC-B
- Routes must be added explicitly in both VPCs
- CIDRs must not overlap

### 2.2 AWS PrivateLink (Service-Level)

```
 ┌──────────────────────────────────┐    ┌──────────────────────────────────┐
 │      Provider VPC (10.2.0.0/16)  │    │      Consumer VPC (10.3.0.0/16)  │
 │                                  │    │                                  │
 │  ┌────────────┐                  │    │                  ┌─────────────┐ │
 │  │  Service    │                  │    │                  │  Application│ │
 │  │  (Backend)  │                  │    │                  │  (Client)   │ │
 │  └──────┬─────┘                  │    │                  └──────┬──────┘ │
 │         │                        │    │                         │        │
 │  ┌──────▼──────┐                 │    │                  ┌──────▼──────┐ │
 │  │     NLB      │                 │    │                  │ VPC Endpoint │ │
 │  │  (internal)  │                 │    │                  │ (Interface)  │ │
 │  └──────┬──────┘                 │    │                  └──────┬──────┘ │
 │         │                        │    │                         │        │
 │  ┌──────▼──────────────┐         │    │                         │        │
 │  │  VPC Endpoint        │  AWS    │    │                         │        │
 │  │  Service             │◄─PrivateLink─┤                         │        │
 │  │  (expose NLB)        │  (ENI)  │    │                         │        │
 │  └─────────────────────┘         │    │                         │        │
 │                                  │    │  Consumer sends traffic to       │
 │                                  │    │  Endpoint ENI → routed via AWS   │
 │                                  │    │  backbone to Provider NLB        │
 └──────────────────────────────────┘    └──────────────────────────────────┘
```

**Key characteristics:**
- Service-oriented: expose specific services, not entire VPCs
- Consumer only accesses exposed ports/services
- No CIDR overlap issues (uses ENIs in consumer VPC)
- Provider controls who can connect (acceptance model)
- Works cross-account natively

### 2.3 AWS Transit Gateway (Hub-and-Spoke)

```
                         ┌────────────────────────┐
                         │   Region A (us-east-1)  │
                         │                        │
  ┌───────────────┐      │  ┌──────────────────┐  │      ┌───────────────┐
  │  Spoke-1 VPC  │      │  │  Transit Gateway  │  │      │  Spoke-2 VPC  │
  │ 10.10.0.0/16  │──────┼──►   (Hub, ASN      │◄─┼──────│ 10.11.0.0/16  │
  │               │ att  │  │    64512)         │  │ att  │               │
  │  ┌─────────┐  │      │  └────────┬─────────┘  │      │  ┌─────────┐  │
  │  │subnet-0 │  │      │           │             │      │  │subnet-0 │  │
  │  │subnet-1 │  │      │      TGW Peering        │      │  │subnet-1 │  │
  │  └─────────┘  │      │           │             │      │  └─────────┘  │
  └───────────────┘      └───────────┼─────────────┘      └───────────────┘
                                     │
                         ┌───────────┼─────────────┐
                         │   Region B│(eu-west-1)  │
                         │           │             │
                         │  ┌────────▼─────────┐   │
                         │  │  Transit Gateway  │   │
                         │  │   (Hub, ASN       │   │
  ┌───────────────┐      │  │    64513)         │   │
  │  Spoke-3 VPC  │──────┼──►                  │   │
  │ 10.12.0.0/16  │ att  │  └──────────────────┘   │
  │               │      │                        │
  │  ┌─────────┐  │      └────────────────────────┘
  │  │subnet-0 │  │
  │  │subnet-1 │  │
  │  └─────────┘  │
  └───────────────┘
```

**Key characteristics:**
- Hub-and-spoke: all VPCs connect to a central TGW
- **Transitive routing**: spoke-1 can reach spoke-2 through TGW (unlike peering)
- Cross-region via TGW peering
- Centralized route management
- Supports thousands of attachments

---

## 3. Use-Case Comparison

| Criteria | VPC Peering | PrivateLink | Transit Gateway |
|---|---|---|---|
| **Topology** | Point-to-point | Service-oriented | Hub-and-spoke |
| **Best for** | 2-5 VPCs needing full network access | Exposing specific services to consumers | 5+ VPCs, centralized networking |
| **Cross-region** | Yes | Limited (same region preferred) | Yes (TGW peering) |
| **Cross-account** | Yes | Yes (primary use case) | Yes (RAM sharing) |
| **Transitive routing** | No | No (by design) | Yes |
| **Max connections** | 125 peering per VPC | Scales per service | 5,000 attachments per TGW |
| **CIDR overlap** | Not allowed | Allowed (uses ENIs) | Not allowed |

### 3.1 Practical Use-Case Scenarios

#### Scenario 1: Shared Database Cluster (e.g., RDS Aurora across teams)

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | Each app VPC peers with the DB VPC. Apps connect to RDS endpoint directly. Simple when < 5 app VPCs. | Good for small scale |
| **PrivateLink** | DB team exposes RDS Proxy behind NLB as an endpoint service. App teams create VPC endpoints. DB team controls access with acceptance + SG. | Best practice — zero CIDR dependency, DB team retains control |
| **Transit Gateway** | All VPCs attach to TGW. Route 10.x.0.0/16 (DB VPC CIDR) via TGW. Works but exposes full DB VPC network. | Overkill unless TGW already exists for other reasons |

**Recommendation**: PrivateLink. The DB team can rotate, scale, or move the DB without impacting consumers.

#### Scenario 2: Centralized Logging / Monitoring (e.g., ELK, Datadog Agent, Prometheus)

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | Peer each app VPC to the logging VPC. Agents in app VPCs push to log collector IP. Each new VPC = new peering + route. | Works but doesn't scale past ~10 VPCs |
| **PrivateLink** | Expose log ingest endpoint (Logstash/OTEL Collector behind NLB) via endpoint service. App VPCs consume it. | Clean. Per-service. Easy to add new consumers. |
| **Transit Gateway** | All VPCs route to logging VPC via TGW. Centralized. One route change propagates to all. | Best when you already have TGW + want bidirectional access (e.g., pull metrics from app VPCs) |

**Recommendation**: PrivateLink for push-only logging. TGW if you also need to pull metrics or access app VPCs from the monitoring VPC.

#### Scenario 3: Multi-Region Active-Active Application

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | Peer us-east-1 VPC with eu-west-1 VPC. Simple for 2 regions. Breaks down at 4+ regions (n^2 peering). | Good for 2-3 regions |
| **PrivateLink** | Not designed for region-level full connectivity. | Not applicable |
| **Transit Gateway** | TGW per region + TGW peering. Add a new region = 1 new TGW + 1 peering attachment. Routes propagate. | Best for 3+ regions |

**Recommendation**: VPC Peering if exactly 2 regions. Transit Gateway at 3+.

#### Scenario 4: Dev/Staging/Prod Environment Isolation (same account)

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | Peer shared-services VPC (CI/CD, artifacts) with dev, staging, prod VPCs. 3 peerings. Never peer dev↔prod directly. | Simple, effective, explicit isolation |
| **PrivateLink** | Expose shared services (artifact repo, internal APIs) as endpoints. Each env VPC consumes only what it needs. | More secure — no broad network access between envs |
| **Transit Gateway** | Central TGW with separate route tables per env. TGW route table for "dev" only sees dev + shared. Prod route table only sees prod + shared. | Most powerful — can enforce network segmentation centrally |

**Recommendation**: VPC Peering for < 5 envs. TGW with route table segmentation for enforced isolation at scale.

#### Scenario 5: Third-Party / Partner Integration

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | Requires cross-account peering. Exposes your full VPC CIDR to the partner. Security risk. | Avoid for external partners |
| **PrivateLink** | Expose only the API/service the partner needs. Partner creates endpoint in their VPC. You control who connects. | Best practice for partner integration |
| **Transit Gateway** | Overkill. Sharing TGW via RAM with external parties gives too much access. | Not recommended for external parties |

**Recommendation**: PrivateLink is the only appropriate choice for external/partner integration.

#### Scenario 6: Centralized Egress / Internet Gateway (NAT consolidation)

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | Cannot do transitive routing. Each VPC still needs its own NAT Gateway. | Not applicable |
| **PrivateLink** | Not designed for routing internet traffic. | Not applicable |
| **Transit Gateway** | All VPCs route 0.0.0.0/0 to TGW → egress VPC with NAT Gateways. Centralizes NAT costs. | Only solution that works |

**Recommendation**: Transit Gateway. This is one of TGW's killer features — saves significant NAT Gateway costs ($32/month/AZ each).

#### Scenario 7: Network Firewall / IDS Inspection

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | No way to insert a firewall in the peering path. | Not possible |
| **PrivateLink** | Not designed for traffic inspection. | Not possible |
| **Transit Gateway** | Route inter-VPC traffic through an inspection VPC (AWS Network Firewall / third-party IDS) using TGW routing. | Only solution for centralized inspection |

**Recommendation**: Transit Gateway. Required for compliance regimes (PCI-DSS, HIPAA) that mandate traffic inspection.

#### Scenario 8: Hybrid Cloud (on-prem ↔ AWS via VPN/Direct Connect)

| Solution | How it works | Verdict |
|---|---|---|
| **VPC Peering** | On-prem connects to one VPC via VPN. That VPC cannot transitively route to other peered VPCs. Dead end. | Doesn't work beyond 1 VPC |
| **PrivateLink** | Can expose specific services to on-prem via PrivateLink + VPN. But limited to service-level. | Works for specific service access |
| **Transit Gateway** | Attach VPN/Direct Connect to TGW. All VPCs reachable from on-prem via TGW routes. Single point of entry. | Best and most common pattern |

**Recommendation**: Transit Gateway for full hybrid connectivity. PrivateLink as a complement for specific services.

### 3.2 Decision Summary

| Your situation | Use |
|---|---|
| 2-3 VPCs, simple connectivity | VPC Peering |
| Expose a service to consumers (internal or external) | PrivateLink |
| 5+ VPCs, any region count | Transit Gateway |
| Centralized NAT / egress | Transit Gateway |
| Network inspection / firewall | Transit Gateway |
| Partner / third-party access | PrivateLink |
| Hybrid (on-prem + AWS) | Transit Gateway + PrivateLink |
| Multi-region active-active (2 regions) | VPC Peering |
| Multi-region active-active (3+ regions) | Transit Gateway |
| Microservices across accounts | PrivateLink + Transit Gateway backbone |

---

## 4. Trade-Off Analysis

| Factor | VPC Peering | PrivateLink | Transit Gateway |
|---|---|---|---|
| **Monthly cost** | $0 (data transfer only: $0.01/GB same-region, ~$0.02/GB cross-region) | ~$7.5/endpoint/month + $0.01/GB processed | ~$36/attachment/month + $0.05/GB processed |
| **Setup complexity** | Low (2-3 resources per connection) | Medium (NLB + Endpoint Service + Endpoint) | High (TGW + attachments + route tables + propagation) |
| **Operational overhead** | Low (but N*(N-1)/2 connections for full mesh) | Medium (manage endpoint services & permissions) | Medium-High (centralized but complex route tables) |
| **Scalability** | Poor (O(n^2) connections) | Excellent (per-service, independent) | Excellent (hub-and-spoke, O(n)) |
| **Security granularity** | Coarse (Security Groups on full VPC CIDR) | Fine (service-level, port-level, acceptance model) | Medium (TGW route tables, can segment) |
| **Latency** | Lowest (direct path) | Low (extra ENI hop) | Slightly higher (TGW hop) |
| **Bandwidth** | No limit (AWS backbone) | No limit | Up to 50 Gbps per VPC attachment |
| **DNS resolution** | Requires manual config | Private DNS supported | Requires DNS setup (Route 53 Resolver) |
| **Failure blast radius** | Single connection | Single endpoint service | TGW failure affects all attached VPCs |
| **Monitoring** | VPC Flow Logs | VPC Flow Logs + Endpoint metrics | TGW Flow Logs + CloudWatch metrics |
| **IaC complexity** | Simple | Medium | High (especially cross-region) |

### Cost Example: 10 VPCs, 100GB/month inter-VPC traffic

| Solution | Monthly estimate |
|---|---|
| VPC Peering (full mesh = 45 connections) | ~$1 (data transfer only) |
| PrivateLink (10 endpoints) | ~$75 + $1 = ~$76 |
| Transit Gateway (10 attachments) | ~$360 + $5 = ~$365 |

---

## 5. Recommendation for Single-Account Multi-Region

Given the current setup (single account, multi-region):

### Short-term (current state, < 5 VPCs per region):
**Use VPC Peering** for cross-region connectivity.
- Simplest to implement and operate
- Lowest cost
- Sufficient when VPC count is small
- Each region's VPC peers directly with counterparts in other regions

### Medium-term (growing to 5-10 VPCs):
**Migrate to Transit Gateway** within each region + TGW peering cross-region.
- Avoids the N^2 peering explosion
- Centralized route management
- Enables network inspection/firewall (AWS Network Firewall integration)
- Prepares for multi-account migration (TGW is shared via RAM)

### For specific service exposure:
**Add PrivateLink** for services that need controlled, service-level access.
- Use alongside either Peering or TGW
- Ideal when third-party integrations or partner access is needed
- Can coexist with TGW-based backbone

### Migration path:
```
Current:     VPC Peering (simple, cross-region)
     │
     ▼
Phase 2:     Transit Gateway (per-region) + TGW Peering (cross-region)
             + PrivateLink for specific services
     │
     ▼
Phase 3:     Multi-account with TGW shared via RAM
             + PrivateLink for cross-account service access
             + Network Firewall for centralized inspection
```

---

## 6. VPC Lattice (Out of Scope – Brief Note)

**Amazon VPC Lattice** is a newer application networking service (GA 2023) that operates at Layer 7 (HTTP/HTTPS/gRPC). Key differences from the three solutions above:

- **Application-layer**: Routes based on HTTP path, headers, methods – not IP/CIDR
- **Service mesh**: Provides service-to-service connectivity with built-in auth (IAM), observability, and traffic management
- **Cross-account native**: Designed for multi-account from day one using AWS RAM
- **No network-level config**: No route tables, no CIDRs, no peering – purely application-level
- **Complements, not replaces**: Use Lattice for app-to-app; use TGW/Peering for network-level connectivity

**When to consider**: If you're building microservices across multiple accounts and need L7 routing, auth, and observability without managing network plumbing.

---

## 7. LocalStack Testing Notes

### Supported features (LocalStack Pro):
- VPC creation, subnets, route tables, security groups: Full support
- VPC Peering (including cross-region): Supported
- Transit Gateway + VPC attachments: Supported
- TGW Peering (cross-region): Supported
- VPC Endpoint Service + Interface Endpoints: Supported
- NLB (Network Load Balancer): Supported

### Limitations:
- **No real data plane**: LocalStack emulates the AWS API control plane. You cannot send actual ICMP/TCP traffic between VPCs. Tests verify resource state (e.g., `active`, `available`), not packet flow.
- **Some state transitions may be instant**: In real AWS, peering acceptance and TGW attachment provisioning take minutes. LocalStack may return `available` immediately.
- **Cross-region is simulated**: All regions run in the same LocalStack container. Useful for testing Terraform code, not for latency/performance testing.

### What these tests validate:
1. Terraform code is syntactically correct and applies cleanly
2. Resource dependencies are correctly modeled
3. Cross-region provider aliases work correctly
4. Route tables, security groups, and attachments reference correct resources
5. All outputs are populated with valid resource IDs

---

## 8. Summary Table

| Solution | Complexity | Cost | Scalability | Security | Best For |
|---|---|---|---|---|---|
| VPC Peering | Low | Low | Poor (O(n^2)) | Coarse | Small deployments (< 5 VPCs) |
| PrivateLink | Medium | Medium | Excellent | Fine-grained | Service exposure, SaaS |
| Transit Gateway | High | High | Excellent (O(n)) | Centralized | Enterprise, many VPCs |

---

*Report generated as part of VPC Connectivity Lab – terraform-aws-localstack*
