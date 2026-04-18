#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TOTAL_PASS=0
TOTAL_FAIL=0

echo "=============================================="
echo "  VPC Connectivity Lab – Full Test Suite"
echo "=============================================="
echo ""

# Setup MiniStack
"$SCRIPT_DIR/setup.sh"
echo ""

run_env_test() {
  local env_name="$1"
  local env_dir="$PROJECT_DIR/environments/$env_name"
  local ok=0

  echo "----------------------------------------------"
  echo "Testing environments/$env_name"
  echo "----------------------------------------------"

  if terraform -chdir="$env_dir" fmt -check; then
    if terraform -chdir="$env_dir" init -input=false; then
      if terraform -chdir="$env_dir" validate; then
        if terraform -chdir="$env_dir" apply -auto-approve; then
          terraform -chdir="$env_dir" output || true

          if [ "$env_name" = "prod" ]; then
            verify_prod_deep_checks "$env_dir"
          fi
          ok=1
        fi
      fi
    fi
  fi

  terraform -chdir="$env_dir" destroy -auto-approve || true

  if [ "$ok" -eq 1 ]; then
    ((TOTAL_PASS++))
  else
    ((TOTAL_FAIL++))
  fi
  echo ""
}

verify_prod_deep_checks() {
  local env_dir="$1"
  local checks_ok=1
  local state_list

  echo "[*] Running deep prod checks (main-vpc + peering)..."

  terraform -chdir="$env_dir" output -raw main_vpc_id > /dev/null || checks_ok=0
  terraform -chdir="$env_dir" output -raw peering_connection_id > /dev/null || checks_ok=0

  state_list="$(terraform -chdir="$env_dir" state list || true)"
  for required_addr in \
    "module.main_vpc.aws_vpc.this" \
    "module.vpc_peering.aws_vpc_peering_connection.this"
  do
    if [[ "$state_list" != *"$required_addr"* ]]; then
      echo "Missing expected state resource: $required_addr"
      checks_ok=0
    fi
  done

  if [ "$checks_ok" -ne 1 ]; then
    echo "Deep prod checks failed."
    return 1
  fi

  echo "Deep prod checks passed."
  return 0
}

run_env_test "dev"
run_env_test "prod"

# Stop containers
"$SCRIPT_DIR/teardown.sh"

# Summary
echo "=============================================="
echo "  Final Summary: $TOTAL_PASS env passed, $TOTAL_FAIL env failed"
echo "=============================================="

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo "Some tests failed. Run individual test scripts for details."
  exit 1
else
  echo "All test suites passed!"
  exit 0
fi
