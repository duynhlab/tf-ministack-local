#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$PROJECT_DIR/environments"

# Detect docker compose command
if docker compose version > /dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose > /dev/null 2>&1; then
  DC="docker-compose"
else
  DC="docker compose"
fi

echo "=== VPC Connectivity Lab – Teardown ==="

# Destroy each environment
for env in vpc-peering privatelink transit-gateway; do
  if [ -d "$ENV_DIR/$env/.terraform" ]; then
    echo "[*] Destroying $env..."
    cd "$ENV_DIR/$env"
    terraform destroy -auto-approve 2>/dev/null || true
  fi
done

# Stop LocalStack
echo "[*] Stopping LocalStack..."
cd "$PROJECT_DIR"
$DC down -v 2>/dev/null || true

echo "Done."
