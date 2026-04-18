# Terraform AWS Networking Lab

Terraform networking lab demonstrating enterprise-like AWS patterns using **MiniStack** — a free, open-source AWS emulator.

| Environment | Emulator | Description |
|---|---|---|
| **dev** | MiniStack | Basic VPC networking validation |
| **prod** | MiniStack | Enterprise topology with VPC Peering, PrivateLink, Transit Gateway |

## Prerequisites

- [Podman](https://podman.io/getting-started/installation) (or Docker) & Compose
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) v2

## Quick Start

```bash
# 1. Start MiniStack
./scripts/setup.sh

# 2. Run full validation workflow
./scripts/test-all.sh

# 3. Teardown when done
./scripts/teardown.sh
```

## Environment Overview

### dev Environment
- **Purpose**: Quick validation and basic networking
- **Emulator**: MiniStack on `http://localhost:4566`
- **Topology**: Single VPC with 3-tier networking (Public/App/Data, 3 AZs)
- **Provider**: AWS provider >= 6.0

### prod Environment
- **Purpose**: Enterprise networking patterns learning
- **Emulator**: MiniStack on `http://localhost:4566`
- **Topology**: Multi-region 3-tier VPC with advanced connectivity:
  - VPC Peering for cross-region connectivity
  - PrivateLink for service-level exposure (disabled by default — MiniStack limitation)
  - Transit Gateway hub-spoke architecture (disabled by default — MiniStack limitation)
  - WAF v2 (optional)
- **Provider**: AWS provider >= 6.0

## Run Environments

### dev Environment

```bash
./scripts/setup.sh

cd environments/dev
terraform init
terraform validate
terraform apply -auto-approve
terraform output
terraform destroy -auto-approve
```

### prod Environment

```bash
./scripts/setup.sh

cd environments/prod
terraform init
terraform validate
terraform apply -auto-approve
terraform output
terraform destroy -auto-approve
```

## Project Structure

```
.
├── docker-compose.yml              # MiniStack container
├── modules/
│   ├── vpc-base/                   # Basic VPC, subnets, route tables, IGW, NAT
│   ├── vpc-peering/                # Cross-region VPC peering connections
│   ├── privatelink/                # NLB + VPC Endpoint Service + Endpoint
│   ├── transit-gateway/            # Multi-region TGW hub-and-spoke
│   └── waf-v2/                     # WAF v2 resources (WebACL, IP Sets, Rule Groups)
├── environments/
│   ├── dev/                        # MiniStack dev (Singapore, 3 AZs)
│   └── prod/                       # MiniStack prod (Multi-region: SG, US-East)
├── iam/                            # IAM case study: cross-account SNS → SQS + IRSA
│   ├── stg/                        # Staging (1 SNS → 1 SQS, cross-region)
│   └── prod/                       # Production (1 SNS → 2 SQS fan-out, multi-region)
├── scripts/
│   ├── setup.sh                    # Start MiniStack (podman/docker)
│   ├── teardown.sh                 # Stop MiniStack and cleanup
│   └── test-all.sh                 # Full validation workflow
├── docs/
│   ├── README.md                   # Architecture documentation
│   ├── subnet.csv                  # IP allocation table (source of truth for CIDRs)
│   ├── support.md                  # MiniStack API coverage matrix
│   └── report.md                   # Architecture analysis and recommendations
└── AGENTS.md                       # AI coding agent guidance and workflow rules
```

## Networking Modules

| Module | Purpose | Key Resources |
|---|---|---|
| **vpc-base** | Foundation networking | VPC, Subnets, Route Tables, IGW, NAT Gateway, Security Groups |
| **vpc-peering** | Cross-region connectivity | VPC Peering Connections, Route Table updates |
| **privatelink** | Service exposure | NLB, VPC Endpoint Service, VPC Endpoints |
| **transit-gateway** | Hub-and-spoke scaling | Transit Gateway, Attachments, Route Tables, Cross-region peering |
| **waf-v2** | Web application firewall | WebACL, IP Sets, Rule Groups |

## Validation Workflow

The `./scripts/test-all.sh` script performs:

1. **Setup**: Start MiniStack and verify health
2. **dev Environment**: fmt → init → validate → apply → output → destroy
3. **prod Environment**: Same + deep checks (main-vpc, peering)
4. **Teardown**: Stop MiniStack

## Documentation

- **[AGENTS.md](AGENTS.md)**: AI coding agent guidance and repository rules
- **[docs/support.md](docs/support.md)**: MiniStack API coverage matrix
- **[docs/subnet.csv](docs/subnet.csv)**: IP allocation table
- **[docs/README.md](docs/README.md)**: Architecture analysis and recommendations

## Troubleshooting

**Container not starting:**
```bash
# Check container logs
podman compose logs
# or: docker compose logs

# Check MiniStack health
curl http://localhost:4566/_ministack/health
```

**CIDR allocation:**
Always consult `docs/subnet.csv` before assigning new CIDR blocks.

**Cross-region TGW peering:**
Set `enable_tgw_cross_region_peering = false` in `environments/prod/terraform.tfvars` if experiencing issues.

## Contributing

Follow the workflow in `AGENTS.md`:
1. Make changes to modules or environments
2. Run full validation (`./scripts/test-all.sh`)
3. Update documentation as needed
