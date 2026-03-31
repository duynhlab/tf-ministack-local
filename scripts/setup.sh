#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Detect docker compose command
if docker compose version > /dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose > /dev/null 2>&1; then
  DC="docker-compose"
else
  echo "ERROR: Neither 'docker compose' nor 'docker-compose' found."
  exit 1
fi

echo "=== VPC Connectivity Lab – Setup ==="

# Check for LocalStack auth token
if [ -z "${LOCALSTACK_AUTH_TOKEN:-}" ]; then
  echo "ERROR: LOCALSTACK_AUTH_TOKEN is not set."
  echo "Export it before running: export LOCALSTACK_AUTH_TOKEN=your_token"
  exit 1
fi

# Start LocalStack
echo "[1/2] Starting LocalStack..."
cd "$PROJECT_DIR"
$DC up -d

# Wait for readiness
echo "[2/2] Waiting for LocalStack to be ready..."
MAX_RETRIES=30
for i in $(seq 1 $MAX_RETRIES); do
  if curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "LocalStack is ready!"
    curl -s http://localhost:4566/_localstack/health | python3 -m json.tool 2>/dev/null || true
    exit 0
  fi
  echo "  Waiting... ($i/$MAX_RETRIES)"
  sleep 3
done

echo "ERROR: LocalStack did not become ready in time."
exit 1
