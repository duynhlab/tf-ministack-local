#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$SCRIPT_DIR")/environments/privatelink"
AWS="AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws --endpoint-url=http://localhost:4566 --region us-east-1"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== Test: PrivateLink (Service Provider/Consumer) ==="

# Deploy
echo "[1/3] Deploying..."
cd "$ENV_DIR"
terraform init -input=false > /dev/null
terraform apply -auto-approve

# Capture outputs
ENDPOINT_ID=$(terraform output -raw vpc_endpoint_id)
ENDPOINT_SVC=$(terraform output -raw endpoint_service_name)
PROVIDER_VPC=$(terraform output -raw provider_vpc_id)
CONSUMER_VPC=$(terraform output -raw consumer_vpc_id)
NLB_DNS=$(terraform output -raw nlb_dns_name)

echo ""
echo "[2/3] Verifying resources..."

# Check provider VPC
if $AWS ec2 describe-vpcs --vpc-ids "$PROVIDER_VPC" > /dev/null 2>&1; then
  pass "Provider VPC $PROVIDER_VPC exists"
else
  fail "Provider VPC not found"
fi

# Check consumer VPC
if $AWS ec2 describe-vpcs --vpc-ids "$CONSUMER_VPC" > /dev/null 2>&1; then
  pass "Consumer VPC $CONSUMER_VPC exists"
else
  fail "Consumer VPC not found"
fi

# Check NLB exists
NLB_STATE=$($AWS elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='$NLB_DNS'].State.Code" --output text 2>/dev/null || echo "UNKNOWN")
if [ -n "$NLB_STATE" ] && [ "$NLB_STATE" != "UNKNOWN" ]; then
  pass "NLB exists (state: $NLB_STATE)"
else
  fail "NLB not found or state unknown"
fi

# Check endpoint service exists
SVC_STATE=$($AWS ec2 describe-vpc-endpoint-services \
  --service-names "$ENDPOINT_SVC" \
  --query 'ServiceDetails[0].ServiceName' --output text 2>/dev/null || echo "UNKNOWN")
if [ "$SVC_STATE" = "$ENDPOINT_SVC" ]; then
  pass "VPC Endpoint Service '$ENDPOINT_SVC' exists"
else
  fail "VPC Endpoint Service not found (got: $SVC_STATE)"
fi

# Check VPC Endpoint state
EP_STATE=$($AWS ec2 describe-vpc-endpoints \
  --vpc-endpoint-ids "$ENDPOINT_ID" \
  --query 'VpcEndpoints[0].State' --output text 2>/dev/null || echo "UNKNOWN")
if [ "$EP_STATE" = "available" ] || [ "$EP_STATE" = "pendingAcceptance" ]; then
  pass "VPC Endpoint $ENDPOINT_ID state: $EP_STATE"
else
  fail "VPC Endpoint state is '$EP_STATE' (expected available or pendingAcceptance)"
fi

# Summary
echo ""
echo "[3/3] Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit "$FAIL"
