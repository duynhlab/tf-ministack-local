#!/usr/bin/env bash
set -uo pipefail

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$SCRIPT_DIR")/environments/vpc-peering"
AWS="aws --endpoint-url=http://localhost:4566 --region us-east-1"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== Test: VPC Peering (Cross-Region) ==="

# Deploy
echo "[1/3] Deploying..."
cd "$ENV_DIR"
terraform init -input=false > /dev/null
terraform apply -auto-approve

# Capture outputs
PEERING_ID=$(terraform output -raw peering_connection_id)
REQUESTER_VPC=$(terraform output -raw requester_vpc_id)
ACCEPTER_VPC=$(terraform output -raw accepter_vpc_id)
REQUESTER_RT=$(terraform output -raw requester_route_table_id)
ACCEPTER_RT=$(terraform output -raw accepter_route_table_id)

echo "[2/3] Verifying resources..."

# Check peering connection exists and is active
echo "Checking peering status..."
PEERING_STATE=$($AWS ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids "$PEERING_ID" \
  --query 'VpcPeeringConnections[0].Status.Code' --output text 2>/dev/null || echo "UNKNOWN")

if [ "$PEERING_STATE" = "active" ]; then
  pass "Peering connection $PEERING_ID is active"
else
  fail "Peering connection state is '$PEERING_STATE' (expected 'active')"
fi

# Check requester VPC exists
echo "Checking requester VPC..."
if $AWS ec2 describe-vpcs --vpc-ids "$REQUESTER_VPC" > /dev/null 2>&1; then
  pass "Requester VPC $REQUESTER_VPC exists"
else
  fail "Requester VPC $REQUESTER_VPC not found"
fi

# Check accepter VPC exists (query in eu-west-1)
echo "Checking accepter VPC..."
AWS_EU="aws --endpoint-url=http://localhost:4566 --region eu-west-1"
if $AWS_EU ec2 describe-vpcs --vpc-ids "$ACCEPTER_VPC" > /dev/null 2>&1; then
  pass "Accepter VPC $ACCEPTER_VPC exists (eu-west-1)"
else
  fail "Accepter VPC $ACCEPTER_VPC not found in eu-west-1"
fi

# Check routes in requester route table
ROUTE_EXISTS=$($AWS ec2 describe-route-tables --route-table-ids "$REQUESTER_RT" \
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='10.1.0.0/16'].VpcPeeringConnectionId" \
  --output text 2>/dev/null || echo "")

if [ -n "$ROUTE_EXISTS" ]; then
  pass "Route to 10.1.0.0/16 via peering exists in requester RT"
else
  fail "Route to accepter CIDR not found in requester route table"
fi

# Check routes in accepter route table
ROUTE_EXISTS_ACCEPTER=$($AWS_EU ec2 describe-route-tables --route-table-ids "$ACCEPTER_RT" \
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='10.0.0.0/16'].VpcPeeringConnectionId" \
  --output text 2>/dev/null || echo "")

if [ -n "$ROUTE_EXISTS_ACCEPTER" ]; then
  pass "Route to 10.0.0.0/16 via peering exists in accepter RT"
else
  fail "Route to requester CIDR not found in accepter route table"
fi

# Summary
echo ""
echo "[3/3] Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit "$FAIL"
