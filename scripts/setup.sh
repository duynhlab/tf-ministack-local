#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Detect compose command (podman-compose > podman compose > docker compose)
if command -v podman-compose > /dev/null 2>&1; then
  DC="podman-compose"
elif podman compose version > /dev/null 2>&1; then
  DC="podman compose"
elif docker compose version > /dev/null 2>&1; then
  DC="docker compose"
else
  echo "ERROR: No compose command found (podman-compose, podman compose, docker compose)."
  exit 1
fi

echo "=== VPC Connectivity Lab – Setup ==="
echo "Using compose command: $DC"

echo "[1/2] Starting MiniStack..."
cd "$PROJECT_DIR"
$DC up -d ministack

# Wait for MiniStack readiness
echo "[2/2] Waiting for MiniStack readiness (:4566)..."
MAX_RETRIES=30
for i in $(seq 1 $MAX_RETRIES); do
  if curl -sf http://localhost:4566/_ministack/health > /dev/null 2>&1; then
    echo "MiniStack is ready!"
    break
  fi
  echo "  Waiting MiniStack... ($i/$MAX_RETRIES)"
  sleep 3
done

if ! curl -sf http://localhost:4566/_ministack/health > /dev/null 2>&1; then
  echo "ERROR: MiniStack did not become ready in time."
  exit 1
fi

echo ""
echo "Health check:"
curl -s http://localhost:4566/_ministack/health | python3 -m json.tool 2>/dev/null || true
