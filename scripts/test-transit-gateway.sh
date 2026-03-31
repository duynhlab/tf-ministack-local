#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$SCRIPT_DIR")/environments/transit-gateway"
AWS_A="aws --endpoint-url=http://localhost:4566 --region us-east-1"
AWS_B="aws --endpoint-url=http://localhost:4566 --region eu-west-1"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== Test: Transit Gateway (Hub-and-Spoke, Multi-Region) ==="

# Deploy
echo "[1/3] Deploying..."
cd "$ENV_DIR"
terraform init -input=false > /dev/null
terraform apply -auto-approve

# Capture outputs
TGW_A=$(terraform output -raw tgw_id_region_a)
TGW_B=$(terraform output -raw tgw_id_region_b)
PEERING_ID=$(terraform output -raw tgw_peering_attachment_id)

echo ""
echo "[2/3] Verifying resources..."

# Check TGW Region A
TGW_A_STATE=$($AWS_A ec2 describe-transit-gateways \
  --transit-gateway-ids "$TGW_A" \
  --query 'TransitGateways[0].State' --output text 2>/dev/null || echo "UNKNOWN")
if [ "$TGW_A_STATE" = "available" ]; then
  pass "TGW Region A ($TGW_A) is available"
else
  fail "TGW Region A state: $TGW_A_STATE (expected available)"
fi

# Check TGW Region B
TGW_B_STATE=$($AWS_B ec2 describe-transit-gateways \
  --transit-gateway-ids "$TGW_B" \
  --query 'TransitGateways[0].State' --output text 2>/dev/null || echo "UNKNOWN")
if [ "$TGW_B_STATE" = "available" ]; then
  pass "TGW Region B ($TGW_B) is available"
else
  fail "TGW Region B state: $TGW_B_STATE (expected available)"
fi

# Check VPC attachments in Region A
ATTACH_COUNT_A=$($AWS_A ec2 describe-transit-gateway-attachments \
  --filters "Name=transit-gateway-id,Values=$TGW_A" "Name=resource-type,Values=vpc" \
  --query 'length(TransitGatewayAttachments)' --output text 2>/dev/null || echo "0")
if [ "$ATTACH_COUNT_A" -ge 2 ]; then
  pass "TGW Region A has $ATTACH_COUNT_A VPC attachments (expected >= 2)"
else
  fail "TGW Region A has $ATTACH_COUNT_A VPC attachments (expected >= 2)"
fi

# Check VPC attachments in Region B
ATTACH_COUNT_B=$($AWS_B ec2 describe-transit-gateway-attachments \
  --filters "Name=transit-gateway-id,Values=$TGW_B" "Name=resource-type,Values=vpc" \
  --query 'length(TransitGatewayAttachments)' --output text 2>/dev/null || echo "0")
if [ "$ATTACH_COUNT_B" -ge 1 ]; then
  pass "TGW Region B has $ATTACH_COUNT_B VPC attachments (expected >= 1)"
else
  fail "TGW Region B has $ATTACH_COUNT_B VPC attachments (expected >= 1)"
fi

# Check TGW Peering attachment
PEERING_STATE=$($AWS_A ec2 describe-transit-gateway-peering-attachments \
  --transit-gateway-attachment-ids "$PEERING_ID" \
  --query 'TransitGatewayPeeringAttachments[0].State' --output text 2>/dev/null || \
  $AWS_A ec2 describe-transit-gateway-attachments \
  --transit-gateway-attachment-ids "$PEERING_ID" \
  --query 'TransitGatewayAttachments[0].State' --output text 2>/dev/null || echo "UNKNOWN")
if [ "$PEERING_STATE" = "available" ] || [ "$PEERING_STATE" = "active" ]; then
  pass "TGW Peering ($PEERING_ID) state: $PEERING_STATE"
else
  fail "TGW Peering state: $PEERING_STATE (expected available)"
fi

# Check spoke VPCs exist
SPOKE_A_JSON=$(terraform output -json spoke_vpc_ids_a)
for key in $(echo "$SPOKE_A_JSON" | python3 -c "import sys,json; [print(k) for k in json.load(sys.stdin)]" 2>/dev/null); do
  VPC_ID=$(echo "$SPOKE_A_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['$key'])")
  if $AWS_A ec2 describe-vpcs --vpc-ids "$VPC_ID" > /dev/null 2>&1; then
    pass "Spoke VPC $key ($VPC_ID) exists in region A"
  else
    fail "Spoke VPC $key ($VPC_ID) not found in region A"
  fi
done

SPOKE_B_JSON=$(terraform output -json spoke_vpc_ids_b)
for key in $(echo "$SPOKE_B_JSON" | python3 -c "import sys,json; [print(k) for k in json.load(sys.stdin)]" 2>/dev/null); do
  VPC_ID=$(echo "$SPOKE_B_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['$key'])")
  if $AWS_B ec2 describe-vpcs --vpc-ids "$VPC_ID" > /dev/null 2>&1; then
    pass "Spoke VPC $key ($VPC_ID) exists in region B"
  else
    fail "Spoke VPC $key ($VPC_ID) not found in region B"
  fi
done

# Summary
echo ""
echo "[3/3] Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit "$FAIL"
