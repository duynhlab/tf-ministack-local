#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

echo "=============================================="
echo "  VPC Connectivity Lab – Full Test Suite"
echo "=============================================="
echo ""

# Setup
"$SCRIPT_DIR/setup.sh"
echo ""

# Run each test
for test in test-vpc-peering test-privatelink test-transit-gateway; do
  echo "----------------------------------------------"
  if "$SCRIPT_DIR/$test.sh"; then
    ((TOTAL_PASS++))
  else
    ((TOTAL_FAIL++))
  fi
  echo ""
done

# Summary
echo "=============================================="
echo "  Final Summary: $TOTAL_PASS suites passed, $TOTAL_FAIL suites failed"
echo "=============================================="

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo "Some tests failed. Run individual test scripts for details."
  exit 1
else
  echo "All test suites passed!"
  exit 0
fi
