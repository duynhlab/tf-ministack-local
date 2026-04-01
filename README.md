# VPC Enterprise Connectivity Lab (LocalStack)

Terraform modules demonstrating three AWS VPC connectivity solutions, fully testable on LocalStack Pro.

| Solution | Module | Description |
|---|---|---|
| **VPC Peering** | `modules/vpc-peering` | Cross-region point-to-point VPC connectivity |
| **PrivateLink** | `modules/privatelink` | Service-level exposure via NLB + VPC Endpoint |
| **Transit Gateway** | `modules/transit-gateway` | Hub-and-spoke with multi-region TGW peering |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) v2
- [LocalStack Pro](https://localstack.cloud/) auth token (required for VPC Peering, TGW, PrivateLink)

## Quick Start

```bash
# 1. Set your LocalStack Pro auth token
export LOCALSTACK_AUTH_TOKEN=your_token_here

# 2. Run all tests (starts LocalStack, deploys & verifies all 3 solutions)
./scripts/test-all.sh

# 3. Teardown when done
./scripts/teardown.sh
```

## Run Individual Solutions

### VPC Peering

```bash
# Start LocalStack (if not already running)
./scripts/setup.sh

# Deploy & test
./scripts/test-vpc-peering.sh

# Or manually:
cd environments/vpc-peering
terraform init
terraform apply -auto-approve
terraform output
```

### PrivateLink

```bash
./scripts/setup.sh
./scripts/test-privatelink.sh

# Or manually:
cd environments/privatelink
terraform init
terraform apply -auto-approve
terraform output
```

### Transit Gateway

```bash
./scripts/setup.sh
./scripts/test-transit-gateway.sh

# Or manually:
cd environments/transit-gateway
terraform init
terraform apply -auto-approve
terraform output
```

## Project Structure

```
.
├── docker-compose.yml              # LocalStack Pro container
├── modules/
│   ├── vpc-peering/                # Reusable module: cross-region VPC peering
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── privatelink/                # Reusable module: NLB + Endpoint Service + Endpoint
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── transit-gateway/            # Reusable module: multi-region TGW hub-and-spoke
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── vpc-peering/                # Root module with LocalStack providers
│   ├── privatelink/
│   └── transit-gateway/
├── scripts/
│   ├── setup.sh                    # Start & wait for LocalStack
│   ├── teardown.sh                 # Destroy all & stop LocalStack
│   ├── test-vpc-peering.sh         # Deploy + verify VPC Peering
│   ├── test-privatelink.sh         # Deploy + verify PrivateLink
│   ├── test-transit-gateway.sh     # Deploy + verify Transit Gateway
│   └── test-all.sh                 # Run everything
└── docs/
    └── report.md                   # Full analysis: use-cases, trade-offs, recommendations
```

## Install docker compsoe cli 

```
mkdir -p ~/.docker/cli-plugins

curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o ~/.docker/cli-plugins/docker-compose

chmod +x ~/.docker/cli-plugins/docker-compose
```

## What Tests Verify

Tests use the AWS CLI against LocalStack to verify:

- Resources are created successfully (`terraform apply` exits 0)
- VPC Peering connection state is `active`
- VPC Endpoint state is `available`
- Transit Gateways are `available` with correct number of attachments
- TGW cross-region peering is established
- Route tables contain expected routes
- All VPCs and subnets exist in correct regions

> **Note**: LocalStack emulates the AWS control plane. Tests verify resource state and configuration, not actual network data plane connectivity.

## Documentation

See [docs/report.md](docs/report.md) for:
- Architecture diagrams for all 3 solutions
- Use-case comparison table
- Detailed trade-off analysis (cost, complexity, scalability, security, latency, ops)
- Recommendation for single-account multi-region → multi-account migration path
- Brief note on VPC Lattice (out of scope)

## Troubleshooting

**LocalStack not starting:**
```bash
# Check container logs
docker compose logs localstack

# Verify auth token
echo $LOCALSTACK_AUTH_TOKEN
```

**Terraform errors with provider endpoints:**
```bash
# Verify LocalStack is healthy
curl http://localhost:4566/_localstack/health
```

**Cross-region resources not found:**
LocalStack handles multi-region in a single container. Ensure your AWS CLI commands use the correct `--region` flag matching the Terraform provider.
