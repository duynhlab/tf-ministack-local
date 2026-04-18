#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$PROJECT_DIR/environments"

# Detect compose command (podman-compose > podman compose > docker compose)
if command -v podman-compose > /dev/null 2>&1; then
  DC="podman-compose"
elif podman compose version > /dev/null 2>&1; then
  DC="podman compose"
elif docker compose version > /dev/null 2>&1; then
  DC="docker compose"
else
  DC="podman compose"
fi

echo "=== VPC Connectivity Lab – Teardown ==="

if [ "${CONFIRM_DESTROY:-0}" = "1" ]; then
  for env in dev prod; do
    if [ -d "$ENV_DIR/$env/.terraform" ]; then
      echo "[*] Destroying $env..."
      cd "$ENV_DIR/$env"
      terraform destroy -auto-approve || true
    fi
  done
else
  echo "[*] Skipping terraform destroy. Set CONFIRM_DESTROY=1 to enable cleanup."
fi

echo "[*] Stopping emulator containers..."
cd "$PROJECT_DIR"
$DC down -v || true

echo "Done."
