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

echo "[1/3] Starting MiniStack..."
cd "$PROJECT_DIR"
$DC up -d ministack

if [ -n "${LOCALSTACK_AUTH_TOKEN:-}" ]; then
  echo "[2/3] Starting LocalStack Pro..."
  $DC up -d localstack_pro
  CHECK_LOCALSTACK_PRO=1
else
  echo "[2/3] Skipping LocalStack Pro (LOCALSTACK_AUTH_TOKEN is not set)."
  echo "      Prod validation requires LOCALSTACK_AUTH_TOKEN."
  CHECK_LOCALSTACK_PRO=0
fi

# Wait for MiniStack readiness
echo "[3/3] Waiting for MiniStack readiness (:4566)..."
MAX_RETRIES=30
for i in $(seq 1 $MAX_RETRIES); do
  if curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "MiniStack is ready!"
    break
  fi
  echo "  Waiting MiniStack... ($i/$MAX_RETRIES)"
  sleep 3
done

if ! curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
  echo "ERROR: MiniStack did not become ready in time."
  exit 1
fi

if [ "$CHECK_LOCALSTACK_PRO" = "1" ]; then
  echo "[*] Waiting for LocalStack Pro readiness (:4567)..."
  for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf http://localhost:4567/_localstack/health > /dev/null 2>&1; then
      echo "LocalStack Pro is ready!"
      break
    fi
    echo "  Waiting LocalStack Pro... ($i/$MAX_RETRIES)"
    sleep 3
  done

  if ! curl -sf http://localhost:4567/_localstack/health > /dev/null 2>&1; then
    echo "ERROR: LocalStack Pro did not become ready in time."
    exit 1
  fi
fi

echo ""
echo "Health checks:"
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool 2>/dev/null || true
if [ "$CHECK_LOCALSTACK_PRO" = "1" ]; then
  curl -s http://localhost:4567/_localstack/health | python3 -m json.tool 2>/dev/null || true
fi
