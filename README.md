# Terraform AWS Networking Lab

Terraform networking lab demonstrating enterprise-like AWS patterns using dual emulators: MiniStack (dev) and LocalStack Pro (prod).

| Environment | Emulator | Description |
|---|---|---|
| **dev** | MiniStack | Basic VPC networking validation |
| **prod** | LocalStack Pro | Enterprise topology with VPC Peering, PrivateLink, Transit Gateway |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) v2
- [LocalStack Pro](https://localstack.cloud/) auth token (required for `prod` environment)

## Quick Start

```bash
# 1. Set your LocalStack Pro auth token (required for prod)
export LOCALSTACK_AUTH_TOKEN=your_token_here

# 2. Run validation workflow
./scripts/test-all.sh

# 3. Teardown when done
./scripts/teardown.sh
```

## Environment Overview

### dev Environment (MiniStack)
- **Purpose**: Quick validation and basic networking
- **Emulator**: MiniStack on `http://localhost:4566`
- **Topology**: Single VPC with basic networking components
- **Provider**: AWS provider v4.x (compatibility with MiniStack limitations)

### prod Environment (LocalStack Pro)
- **Purpose**: Enterprise networking patterns learning
- **Emulator**: LocalStack Pro on `http://localhost:4567`
- **Topology**: 3-tier VPC (Public/App/Data) with advanced connectivity:
  - VPC Peering for cross-region connectivity
  - PrivateLink for service-level exposure
  - Transit Gateway hub-spoke architecture
- **Provider**: AWS provider v5+ (full feature support)

## Run Environments

### dev Environment

```bash
# Start MiniStack emulator
./scripts/setup.sh

# Deploy basic VPC networking
cd environments/dev
terraform init
terraform validate
terraform apply -auto-approve
terraform output

# Cleanup
terraform destroy -auto-approve
```

### prod Environment

```bash
# Start LocalStack Pro emulator (requires LOCALSTACK_AUTH_TOKEN)
./scripts/setup.sh

# Deploy enterprise networking topology
cd environments/prod
terraform init
terraform validate
terraform apply -auto-approve
terraform output

# Cleanup
terraform destroy -auto-approve
```

## Project Structure

```
.
├── docker-compose.yml              # Dual emulator containers (MiniStack + LocalStack Pro)
├── modules/
│   ├── vpc-base/                   # Basic VPC, subnets, route tables, IGW, NAT
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc-peering/                # Cross-region VPC peering connections
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── privatelink/                # NLB + VPC Endpoint Service + Endpoint
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── transit-gateway/            # Multi-region TGW hub-and-spoke
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── waf-v2/                     # WAF v2 resources (WebACL, IP Sets, Rule Groups)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/                        # MiniStack environment (basic VPC)
│   │   ├── main.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/                       # LocalStack Pro environment (enterprise topology)
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── scripts/
│   ├── setup.sh                    # Start both emulators
│   ├── teardown.sh                 # Stop emulators and cleanup
│   └── test-all.sh                 # Full validation workflow
├── docs/
│   ├── README.md                   # Additional documentation
│   ├── subnet.csv                  # IP allocation table (source of truth for CIDRs)
│   ├── support.md                  # MiniStack vs LocalStack capability matrix
│   ├── changelog.md                # Provider version decisions and upgrade notes
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
| **waf-v2** | Web application firewall | WebACL, IP Sets, Rule Groups, Logging |

## Validation Workflow

The `./scripts/test-all.sh` script performs the complete validation workflow:

1. **Setup**: Start both emulators and verify health
2. **dev Environment**:
   - Format check (`terraform fmt -check`)
   - Initialize (`terraform init`)
   - Validate configuration (`terraform validate`)
   - Deploy resources (`terraform apply`)
   - Verify outputs (`terraform output`)
   - Destroy resources (`terraform destroy`)
3. **prod Environment**:
   - Same validation steps as dev
   - Additional verification of enterprise networking patterns
4. **Teardown**: Stop emulators

## Documentation

- **[AGENTS.md](AGENTS.md)**: AI coding agent guidance and repository rules
- **[docs/support.md](docs/support.md)**: MiniStack vs LocalStack Pro capability matrix
- **[docs/subnet.csv](docs/subnet.csv)**: IP allocation table (consult before assigning CIDRs)
- **[docs/changelog.md](docs/changelog.md)**: Provider version decisions and upgrade guidance
- **[docs/report.md](docs/report.md)**: Architecture analysis and recommendations

## Troubleshooting

**Emulators not starting:**
```bash
# Check container logs
docker compose logs

# Verify LocalStack Pro auth token (required for prod)
echo $LOCALSTACK_AUTH_TOKEN

# Check emulator health
curl http://localhost:4566/_localstack/health  # MiniStack (dev)
curl http://localhost:4567/_localstack/health  # LocalStack Pro (prod)
```

**Terraform provider compatibility:**
- **dev**: Use AWS provider ~4.67 (MiniStack compatibility)
- **prod**: Use AWS provider v5+ (full feature support)

**CIDR allocation:**
Always consult `docs/subnet.csv` before assigning new CIDR blocks to avoid conflicts.

**Cross-region peering issues:**
In LocalStack Pro, disable `enable_cross_region_peering` in `environments/prod/terraform.tfvars` if experiencing hangs.

## Contributing

Follow the workflow in `AGENTS.md`:
1. Make changes to modules or environments
2. Run full validation (`./scripts/test-all.sh`)
3. Update documentation as needed
4. Commit and push changes
