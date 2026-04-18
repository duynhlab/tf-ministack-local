#!/usr/bin/env bash
# scripts/validate-ministack-apis.sh
# Probes every API in docs/support.md against MiniStack :4566
# Usage: ./scripts/setup.sh && ./scripts/validate-ministack-apis.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENDPOINT="http://localhost:4566"
REGION="ap-southeast-1"
REPORT_FILE="$PROJECT_DIR/docs/report-ministack-api.md"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RUN_ID="ms$$"

# ── Tracking ──────────────────────────────────────────────────────────────────
declare -a PASS_LIST=()
declare -a FAIL_LIST=()
declare -a SKIP_LIST=()
CURRENT_SECTION=""

# ── Resource IDs ──────────────────────────────────────────────────────────────
S3_BUCKET="validate-${RUN_ID}"
IAM_ROLE="validate-role-${RUN_ID}"
IAM_USER="validate-user-${RUN_ID}"
IAM_GROUP="validate-grp-${RUN_ID}"
IAM_PROFILE="validate-prof-${RUN_ID}"
IAM_POLICY_ARN=""
IAM_AK_ID=""
VPC_ID="" SUBNET_ID="" RTB_ID="" ASSOC_ID="" IGW_ID="" EOIGW_ID=""
SG_ID="" EIP_ALLOC_ID="" ENI_ID="" NACL_ID="" DHCP_ID=""
VOLUME_ID="" INSTANCE_ID="" NAT_GW_ID="" VPC_PEER_ID=""
VPC_EP_ID="" PREFIX_LIST_ID="" VPN_GW_ID="" CGW_ID=""
KP_NAME="validate-kp-${RUN_ID}"
WAF_ACL_ID="" WAF_ACL_LOCK="" WAF_ACL_ARN=""
WAF_IPSET_ID="" WAF_IPSET_LOCK=""
WAF_RG_ID="" WAF_RG_LOCK=""
CF_DIST_ID="" CF_ETAG=""
ECR_REPO="validate-repo-${RUN_ID}"
APPSYNC_ID="" APPSYNC_KEY_ID=""
COGNITO_POOL_ID="" COGNITO_CLIENT_ID=""
KMS_KEY_ID="" KMS_KEY_ARN=""
HOSTED_ZONE_ID=""
LAMBDA_NAME="validate-fn-${RUN_ID}"
LAMBDA_ZIP="/tmp/validate-lambda-${RUN_ID}.zip"

# ── Cleanup ───────────────────────────────────────────────────────────────────
cleanup_fns=()
cleanup() {
  echo ""
  echo "[cleanup] Removing probe resources..."
  for fn in "${cleanup_fns[@]:-}"; do eval "$fn" 2>/dev/null || true; done
  rm -f "$LAMBDA_ZIP" /tmp/s3get-${RUN_ID} 2>/dev/null || true
  echo "[cleanup] Done."
}
trap cleanup EXIT

# ── AWS CLI wrapper ───────────────────────────────────────────────────────────
A() {
  AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test \
  AWS_DEFAULT_REGION="$REGION" \
  aws --endpoint-url="$ENDPOINT" --output json "$@" 2>&1
}

# ── Probe helpers ──────────────────────────────────────────────────────────────
section() { CURRENT_SECTION="$1"; echo ""; echo "[$1]"; }

probe() {
  local api="$1"; shift
  local out
  out=$(A "$@" 2>&1)
  if echo "$out" | grep -qiE 'InvalidAction|Unknown.*action|UnknownOperation|NotImplemented|UnsupportedOperation'; then
    FAIL_LIST+=("${CURRENT_SECTION}|${api}")
    printf "  FAIL  %s\n" "$api"
  else
    PASS_LIST+=("${CURRENT_SECTION}|${api}")
    printf "  PASS  %s\n" "$api"
  fi
}

skip_probe() {
  SKIP_LIST+=("${CURRENT_SECTION}|${1}|${2}")
  printf "  SKIP  %s  (%s)\n" "$1" "$2"
}

# ── Health check ──────────────────────────────────────────────────────────────
echo "=============================================="
echo "  MiniStack API Validation"
echo "  Endpoint: $ENDPOINT | $(date -u)"
echo "=============================================="
if ! curl -sf "$ENDPOINT/_ministack/health" > /dev/null 2>&1; then
  echo "ERROR: MiniStack not running. Run ./scripts/setup.sh first."; exit 1
fi
MS_VER=$(curl -s "$ENDPOINT/_ministack/health" 2>/dev/null \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('version','unknown'))" 2>/dev/null || echo "unknown")
echo "Version: $MS_VER"

# ═════════════════════════════════════════════════════════════════════════════
# S3
# ═════════════════════════════════════════════════════════════════════════════
section "S3"
A s3api create-bucket --bucket "$S3_BUCKET" \
  --create-bucket-configuration LocationConstraint="$REGION" > /dev/null 2>&1 || true
cleanup_fns+=("A s3 rb s3://$S3_BUCKET --force")

BUCKET2="${S3_BUCKET}-b"
probe "CreateBucket"    s3api create-bucket --bucket "$BUCKET2" \
  --create-bucket-configuration LocationConstraint="$REGION"
A s3api delete-bucket --bucket "$BUCKET2" > /dev/null 2>&1 || true
probe "DeleteBucket"    s3api delete-bucket --bucket "$BUCKET2"  # already gone = API exists
probe "ListBuckets"     s3api list-buckets
probe "HeadBucket"      s3api head-bucket --bucket "$S3_BUCKET"
A s3api put-object --bucket "$S3_BUCKET" --key probe-key --body /dev/null > /dev/null 2>&1
probe "PutObject"       s3api put-object --bucket "$S3_BUCKET" --key probe-obj --body /dev/null
probe "GetObject"       s3api get-object --bucket "$S3_BUCKET" --key probe-key /tmp/s3get-${RUN_ID}
probe "HeadObject"      s3api head-object --bucket "$S3_BUCKET" --key probe-key
probe "CopyObject"      s3api copy-object --bucket "$S3_BUCKET" \
  --copy-source "${S3_BUCKET}/probe-key" --key probe-key-copy
probe "DeleteObject"    s3api delete-object --bucket "$S3_BUCKET" --key probe-key
probe "ListObjects v1/v2" s3api list-objects-v2 --bucket "$S3_BUCKET"
probe "DeleteObjects (batch)" s3api delete-objects --bucket "$S3_BUCKET" \
  --delete '{"Objects":[{"Key":"probe-key-copy"}]}'

# Multipart
MP_ID=$(A s3api create-multipart-upload --bucket "$S3_BUCKET" --key probe-mp \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['UploadId'])" 2>/dev/null || echo "")
probe "CreateMultipartUpload" s3api create-multipart-upload --bucket "$S3_BUCKET" --key probe-mp2
if [ -n "$MP_ID" ]; then
  A s3api put-object --bucket "$S3_BUCKET" --key probe-src --body /dev/null > /dev/null 2>&1 || true
  probe "UploadPartCopy" s3api upload-part-copy --bucket "$S3_BUCKET" --key probe-mp \
    --upload-id "$MP_ID" --part-number 1 --copy-source "${S3_BUCKET}/probe-src"
  probe "AbortMultipartUpload" s3api abort-multipart-upload \
    --bucket "$S3_BUCKET" --key probe-mp --upload-id "$MP_ID"
else
  skip_probe "UploadPartCopy"     "no upload ID"
  skip_probe "AbortMultipartUpload" "no upload ID"
fi

probe "GetBucketVersioning"  s3api get-bucket-versioning --bucket "$S3_BUCKET"
probe "PutBucketVersioning"  s3api put-bucket-versioning --bucket "$S3_BUCKET" \
  --versioning-configuration Status=Enabled
probe "ListObjectVersions"   s3api list-object-versions --bucket "$S3_BUCKET"
probe "PutBucketEncryption"  s3api put-bucket-encryption --bucket "$S3_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
probe "GetBucketEncryption"  s3api get-bucket-encryption  --bucket "$S3_BUCKET"
probe "DeleteBucketEncryption" s3api delete-bucket-encryption --bucket "$S3_BUCKET"
probe "PutBucketLifecycleConfiguration" s3api put-bucket-lifecycle-configuration \
  --bucket "$S3_BUCKET" \
  --lifecycle-configuration '{"Rules":[{"ID":"p","Status":"Enabled","Expiration":{"Days":1},"Filter":{"Prefix":""}}]}'
probe "GetBucketLifecycleConfiguration" s3api get-bucket-lifecycle-configuration --bucket "$S3_BUCKET"
probe "DeleteBucketLifecycle" s3api delete-bucket-lifecycle --bucket "$S3_BUCKET"
probe "PutBucketCors"      s3api put-bucket-cors --bucket "$S3_BUCKET" \
  --cors-configuration '{"CORSRules":[{"AllowedOrigins":["*"],"AllowedMethods":["GET"]}]}'
probe "GetBucketCors"      s3api get-bucket-cors --bucket "$S3_BUCKET"
probe "DeleteBucketCors"   s3api delete-bucket-cors --bucket "$S3_BUCKET"
probe "GetBucketAcl"       s3api get-bucket-acl --bucket "$S3_BUCKET"
probe "PutBucketAcl"       s3api put-bucket-acl --bucket "$S3_BUCKET" --acl private
probe "PutBucketTagging"   s3api put-bucket-tagging --bucket "$S3_BUCKET" \
  --tagging 'TagSet=[{Key=probe,Value=yes}]'
probe "GetBucketTagging"   s3api get-bucket-tagging --bucket "$S3_BUCKET"
probe "DeleteBucketTagging" s3api delete-bucket-tagging --bucket "$S3_BUCKET"
probe "PutBucketPolicy"    s3api put-bucket-policy --bucket "$S3_BUCKET" \
  --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::${S3_BUCKET}/*\"}]}"
probe "GetBucketPolicy"    s3api get-bucket-policy --bucket "$S3_BUCKET"
probe "DeleteBucketPolicy" s3api delete-bucket-policy --bucket "$S3_BUCKET"
probe "PutBucketNotificationConfiguration" s3api put-bucket-notification-configuration \
  --bucket "$S3_BUCKET" --notification-configuration '{}'
probe "GetBucketNotificationConfiguration" s3api get-bucket-notification-configuration \
  --bucket "$S3_BUCKET"
probe "PutBucketLogging"   s3api put-bucket-logging --bucket "$S3_BUCKET" \
  --bucket-logging-status '{}'
probe "GetBucketLogging"   s3api get-bucket-logging  --bucket "$S3_BUCKET"
probe "PutBucketReplication" s3api put-bucket-replication --bucket "$S3_BUCKET" \
  --replication-configuration \
  '{"Role":"arn:aws:iam::000000000000:role/r","Rules":[{"Status":"Enabled","Destination":{"Bucket":"arn:aws:s3:::dest"}}]}'
probe "GetBucketReplication"    s3api get-bucket-replication    --bucket "$S3_BUCKET"
probe "DeleteBucketReplication" s3api delete-bucket-replication --bucket "$S3_BUCKET"

OL_BUCKET="${S3_BUCKET}-ol"
A s3api create-bucket --bucket "$OL_BUCKET" \
  --create-bucket-configuration LocationConstraint="$REGION" \
  --object-lock-enabled-for-bucket > /dev/null 2>&1 || true
cleanup_fns+=("A s3 rb s3://$OL_BUCKET --force")
probe "PutObjectLockConfiguration" s3api put-object-lock-configuration --bucket "$OL_BUCKET" \
  --object-lock-configuration '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"GOVERNANCE","Days":1}}}'
probe "GetObjectLockConfiguration" s3api get-object-lock-configuration --bucket "$OL_BUCKET"
A s3api put-object --bucket "$OL_BUCKET" --key lock-obj --body /dev/null > /dev/null 2>&1 || true
probe "PutObjectRetention" s3api put-object-retention --bucket "$OL_BUCKET" --key lock-obj \
  --retention '{"Mode":"GOVERNANCE","RetainUntilDate":"2030-01-01T00:00:00Z"}' \
  --bypass-governance-retention
probe "GetObjectRetention" s3api get-object-retention --bucket "$OL_BUCKET" --key lock-obj
probe "PutObjectLegalHold" s3api put-object-legal-hold --bucket "$OL_BUCKET" --key lock-obj \
  --legal-hold '{"Status":"ON"}'
probe "GetObjectLegalHold" s3api get-object-legal-hold --bucket "$OL_BUCKET" --key lock-obj
skip_probe "S3 disk persistence" "env-config (S3_PERSIST=1), not an API"
probe "S3 Control ListTagsForResource" s3control list-tags-for-resource \
  --account-id 000000000000 --resource-arn "arn:aws:s3:::${S3_BUCKET}"

# ═════════════════════════════════════════════════════════════════════════════
# IAM
# ═════════════════════════════════════════════════════════════════════════════
section "IAM"
TRUST='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
POLICY_DOC='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListBucket","Resource":"*"}]}'

A iam create-user --user-name "$IAM_USER" > /dev/null 2>&1 || true
A iam create-role --role-name "$IAM_ROLE" --assume-role-policy-document "$TRUST" > /dev/null 2>&1 || true
cleanup_fns+=("A iam delete-user --user-name '$IAM_USER'")
cleanup_fns+=("A iam delete-role --role-name '$IAM_ROLE'")

probe "CreateUser"  iam create-user --user-name "${IAM_USER}-2"
A iam delete-user --user-name "${IAM_USER}-2" > /dev/null 2>&1 || true
probe "GetUser"     iam get-user  --user-name "$IAM_USER"
probe "ListUsers"   iam list-users
probe "DeleteUser"  iam delete-user --user-name "${IAM_USER}-2"   # already gone

probe "CreateRole"  iam create-role --role-name "${IAM_ROLE}-2" \
  --assume-role-policy-document "$TRUST"
A iam delete-role --role-name "${IAM_ROLE}-2" > /dev/null 2>&1 || true
probe "GetRole"     iam get-role  --role-name "$IAM_ROLE"
probe "ListRoles"   iam list-roles
probe "DeleteRole"  iam delete-role --role-name "${IAM_ROLE}-2"

IAM_POLICY_ARN=$(A iam create-policy --policy-name "validate-pol-${RUN_ID}" \
  --policy-document "$POLICY_DOC" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['Policy']['Arn'])" 2>/dev/null || echo "")
cleanup_fns+=("A iam delete-policy --policy-arn '${IAM_POLICY_ARN:-arn:aws:iam::000000000000:policy/x}'")

probe "CreatePolicy"  iam create-policy \
  --policy-name "validate-pol2-${RUN_ID}" --policy-document "$POLICY_DOC"
probe "GetPolicy"     iam get-policy --policy-arn "${IAM_POLICY_ARN:-arn:aws:iam::000000000000:policy/x}"
probe "DeletePolicy"  iam delete-policy --policy-arn "arn:aws:iam::000000000000:policy/validate-pol2-${RUN_ID}"

probe "AttachRolePolicy" iam attach-role-policy \
  --role-name "$IAM_ROLE" --policy-arn "${IAM_POLICY_ARN:-arn:aws:iam::aws:policy/ReadOnlyAccess}"
probe "DetachRolePolicy" iam detach-role-policy \
  --role-name "$IAM_ROLE" --policy-arn "${IAM_POLICY_ARN:-arn:aws:iam::aws:policy/ReadOnlyAccess}"
probe "PutRolePolicy (inline)" iam put-role-policy \
  --role-name "$IAM_ROLE" --policy-name "inline" --policy-document "$POLICY_DOC"
probe "GetRolePolicy"  iam get-role-policy  --role-name "$IAM_ROLE" --policy-name "inline"
probe "DeleteRolePolicy" iam delete-role-policy --role-name "$IAM_ROLE" --policy-name "inline"
probe "ListRolePolicies" iam list-role-policies --role-name "$IAM_ROLE"
probe "ListAttachedRolePolicies" iam list-attached-role-policies --role-name "$IAM_ROLE"

AK_JSON=$(A iam create-access-key --user-name "$IAM_USER" 2>/dev/null || echo "")
IAM_AK_ID=$(echo "$AK_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])" 2>/dev/null || echo "")
probe "CreateAccessKey" iam create-access-key --user-name "$IAM_USER"
probe "ListAccessKeys"  iam list-access-keys  --user-name "$IAM_USER"
if [ -n "$IAM_AK_ID" ]; then
  probe "DeleteAccessKey" iam delete-access-key --user-name "$IAM_USER" --access-key-id "$IAM_AK_ID"
else
  skip_probe "DeleteAccessKey" "no access key ID"
fi

A iam create-instance-profile --instance-profile-name "$IAM_PROFILE" > /dev/null 2>&1 || true
cleanup_fns+=("A iam delete-instance-profile --instance-profile-name '$IAM_PROFILE'")
probe "CreateInstanceProfile"  iam create-instance-profile --instance-profile-name "${IAM_PROFILE}-2"
A iam delete-instance-profile --instance-profile-name "${IAM_PROFILE}-2" > /dev/null 2>&1 || true
probe "GetInstanceProfile"     iam get-instance-profile --instance-profile-name "$IAM_PROFILE"
probe "AddRoleToInstanceProfile" iam add-role-to-instance-profile \
  --instance-profile-name "$IAM_PROFILE" --role-name "$IAM_ROLE"
probe "RemoveRoleFromInstanceProfile" iam remove-role-from-instance-profile \
  --instance-profile-name "$IAM_PROFILE" --role-name "$IAM_ROLE"
probe "ListInstanceProfiles"   iam list-instance-profiles
probe "DeleteInstanceProfile"  iam delete-instance-profile --instance-profile-name "${IAM_PROFILE}-2"

A iam create-group --group-name "$IAM_GROUP" > /dev/null 2>&1 || true
cleanup_fns+=("A iam delete-group --group-name '$IAM_GROUP'")
probe "CreateGroup"        iam create-group --group-name "${IAM_GROUP}-2"
A iam delete-group --group-name "${IAM_GROUP}-2" > /dev/null 2>&1 || true
probe "GetGroup"           iam get-group   --group-name "$IAM_GROUP"
probe "AddUserToGroup"     iam add-user-to-group    --group-name "$IAM_GROUP" --user-name "$IAM_USER"
probe "RemoveUserFromGroup" iam remove-user-from-group --group-name "$IAM_GROUP" --user-name "$IAM_USER"

probe "CreateServiceLinkedRole" iam create-service-linked-role \
  --aws-service-name elasticloadbalancing.amazonaws.com
probe "CreateOpenIDConnectProvider" iam create-open-id-connect-provider \
  --url "https://token.example.com" --client-id-list "test-client" \
  --thumbprint-list "0000000000000000000000000000000000000000"
probe "TagRole / UntagRole"  iam tag-role   --role-name "$IAM_ROLE" --tags Key=probe,Value=yes
probe "TagUser / UntagUser"  iam tag-user   --user-name "$IAM_USER" --tags Key=probe,Value=yes
probe "TagPolicy / UntagPolicy" iam tag-policy \
  --policy-arn "${IAM_POLICY_ARN:-arn:aws:iam::000000000000:policy/x}" --tags Key=probe,Value=yes
skip_probe "IAM policy enforcement" "behavioral (not enforced on MiniStack)"

# ═════════════════════════════════════════════════════════════════════════════
# STS
# ═════════════════════════════════════════════════════════════════════════════
section "STS"
probe "GetCallerIdentity"      sts get-caller-identity
probe "AssumeRole"             sts assume-role \
  --role-arn "arn:aws:iam::000000000000:role/${IAM_ROLE}" \
  --role-session-name probe-session
probe "GetSessionToken"        sts get-session-token
probe "AssumeRoleWithWebIdentity" sts assume-role-with-web-identity \
  --role-arn "arn:aws:iam::000000000000:role/${IAM_ROLE}" \
  --role-session-name probe-wid \
  --web-identity-token "dummy-token"

# ═════════════════════════════════════════════════════════════════════════════
# WAF v2
# ═════════════════════════════════════════════════════════════════════════════
section "WAF v2"
WAF_SCOPE="REGIONAL"
IPSET_JSON=$(A wafv2 create-ip-set --name "probe-ipset-${RUN_ID}" --scope "$WAF_SCOPE" \
  --ip-address-version IPV4 --addresses '[]' 2>/dev/null || echo "")
WAF_IPSET_ID=$(echo "$IPSET_JSON"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Summary']['Id'])"  2>/dev/null || echo "")
WAF_IPSET_LOCK=$(echo "$IPSET_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Summary']['LockToken'])" 2>/dev/null || echo "")
cleanup_fns+=("A wafv2 delete-ip-set --name 'probe-ipset-${RUN_ID}' --scope '$WAF_SCOPE' --id '${WAF_IPSET_ID:-x}' --lock-token 'x'")

probe "CreateIPSet"   wafv2 create-ip-set --name "probe-ipset2-${RUN_ID}" \
  --scope "$WAF_SCOPE" --ip-address-version IPV4 --addresses '[]'
probe "GetIPSet"      wafv2 get-ip-set \
  --name "probe-ipset-${RUN_ID}" --scope "$WAF_SCOPE" --id "${WAF_IPSET_ID:-x}"
probe "ListIPSets"    wafv2 list-ip-sets --scope "$WAF_SCOPE"
if [ -n "$WAF_IPSET_ID" ] && [ -n "$WAF_IPSET_LOCK" ]; then
  probe "UpdateIPSet" wafv2 update-ip-set \
    --name "probe-ipset-${RUN_ID}" --scope "$WAF_SCOPE" --id "$WAF_IPSET_ID" \
    --lock-token "$WAF_IPSET_LOCK" --addresses '["1.2.3.4/32"]'
  FRESH_LOCK=$(A wafv2 get-ip-set --name "probe-ipset-${RUN_ID}" --scope "$WAF_SCOPE" --id "$WAF_IPSET_ID" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['LockToken'])" 2>/dev/null || echo "x")
  probe "DeleteIPSet" wafv2 delete-ip-set \
    --name "probe-ipset-${RUN_ID}" --scope "$WAF_SCOPE" --id "$WAF_IPSET_ID" --lock-token "$FRESH_LOCK"
else
  skip_probe "UpdateIPSet" "no ipset ID/lock"
  skip_probe "DeleteIPSet" "no ipset ID/lock"
fi

RG_JSON=$(A wafv2 create-rule-group --name "probe-rg-${RUN_ID}" --scope "$WAF_SCOPE" \
  --capacity 10 --visibility-config \
  'SampledRequestsEnabled=false,CloudWatchMetricsEnabled=false,MetricName=probe' 2>/dev/null || echo "")
WAF_RG_ID=$(echo "$RG_JSON"   | python3 -c "import sys,json; print(json.load(sys.stdin)['Summary']['Id'])"  2>/dev/null || echo "")
WAF_RG_LOCK=$(echo "$RG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['Summary']['LockToken'])" 2>/dev/null || echo "")

probe "CreateRuleGroup" wafv2 create-rule-group --name "probe-rg2-${RUN_ID}" \
  --scope "$WAF_SCOPE" --capacity 10 --visibility-config \
  'SampledRequestsEnabled=false,CloudWatchMetricsEnabled=false,MetricName=probe'
probe "GetRuleGroup"  wafv2 get-rule-group \
  --name "probe-rg-${RUN_ID}" --scope "$WAF_SCOPE" --id "${WAF_RG_ID:-x}"
probe "ListRuleGroups" wafv2 list-rule-groups --scope "$WAF_SCOPE"
if [ -n "$WAF_RG_ID" ] && [ -n "$WAF_RG_LOCK" ]; then
  probe "UpdateRuleGroup" wafv2 update-rule-group \
    --name "probe-rg-${RUN_ID}" --scope "$WAF_SCOPE" --id "$WAF_RG_ID" \
    --lock-token "$WAF_RG_LOCK" --visibility-config \
    'SampledRequestsEnabled=false,CloudWatchMetricsEnabled=false,MetricName=probe'
  FRESH_RG_LOCK=$(A wafv2 get-rule-group --name "probe-rg-${RUN_ID}" --scope "$WAF_SCOPE" \
    --id "$WAF_RG_ID" | python3 -c "import sys,json; print(json.load(sys.stdin)['LockToken'])" 2>/dev/null || echo "x")
  probe "DeleteRuleGroup" wafv2 delete-rule-group \
    --name "probe-rg-${RUN_ID}" --scope "$WAF_SCOPE" --id "$WAF_RG_ID" --lock-token "$FRESH_RG_LOCK"
else
  skip_probe "UpdateRuleGroup" "no rule group ID/lock"
  skip_probe "DeleteRuleGroup" "no rule group ID/lock"
fi

ACL_JSON=$(A wafv2 create-web-acl --name "probe-acl-${RUN_ID}" --scope "$WAF_SCOPE" \
  --default-action Allow={} --visibility-config \
  'SampledRequestsEnabled=false,CloudWatchMetricsEnabled=false,MetricName=probe' 2>/dev/null || echo "")
WAF_ACL_ID=$(echo "$ACL_JSON"   | python3 -c "import sys,json; print(json.load(sys.stdin)['Summary']['Id'])"  2>/dev/null || echo "")
WAF_ACL_LOCK=$(echo "$ACL_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['Summary']['LockToken'])" 2>/dev/null || echo "")
WAF_ACL_ARN=$(echo "$ACL_JSON"  | python3 -c "import sys,json; print(json.load(sys.stdin)['Summary']['ARN'])" 2>/dev/null || echo "")
cleanup_fns+=("LOCK=\$(A wafv2 get-web-acl --name 'probe-acl-${RUN_ID}' --scope '$WAF_SCOPE' --id '${WAF_ACL_ID:-x}' | python3 -c \"import sys,json; print(json.load(sys.stdin)['LockToken'])\" 2>/dev/null || echo x); A wafv2 delete-web-acl --name 'probe-acl-${RUN_ID}' --scope '$WAF_SCOPE' --id '${WAF_ACL_ID:-x}' --lock-token \$LOCK")

probe "CreateWebACL"  wafv2 create-web-acl --name "probe-acl2-${RUN_ID}" \
  --scope "$WAF_SCOPE" --default-action Allow={} --visibility-config \
  'SampledRequestsEnabled=false,CloudWatchMetricsEnabled=false,MetricName=probe'
probe "GetWebACL"     wafv2 get-web-acl \
  --name "probe-acl-${RUN_ID}" --scope "$WAF_SCOPE" --id "${WAF_ACL_ID:-x}"
probe "ListWebACLs"   wafv2 list-web-acls --scope "$WAF_SCOPE"
if [ -n "$WAF_ACL_ID" ] && [ -n "$WAF_ACL_LOCK" ]; then
  probe "UpdateWebACL" wafv2 update-web-acl \
    --name "probe-acl-${RUN_ID}" --scope "$WAF_SCOPE" --id "$WAF_ACL_ID" \
    --lock-token "$WAF_ACL_LOCK" --default-action Allow={} --visibility-config \
    'SampledRequestsEnabled=false,CloudWatchMetricsEnabled=false,MetricName=probe'
fi

if [ -n "$WAF_ACL_ARN" ]; then
  probe "TagResource"          wafv2 tag-resource --resource-arn "$WAF_ACL_ARN" \
    --tags Key=probe,Value=yes
  probe "UntagResource"        wafv2 untag-resource --resource-arn "$WAF_ACL_ARN" \
    --tag-keys probe
  probe "ListTagsForResource"  wafv2 list-tags-for-resource --resource-arn "$WAF_ACL_ARN"
  probe "AssociateWebACL"      wafv2 associate-web-acl \
    --web-acl-arn "$WAF_ACL_ARN" \
    --resource-arn "arn:aws:elasticloadbalancing:${REGION}:000000000000:loadbalancer/app/probe/x"
  probe "DisassociateWebACL"   wafv2 disassociate-web-acl \
    --resource-arn "arn:aws:elasticloadbalancing:${REGION}:000000000000:loadbalancer/app/probe/x"
  probe "GetWebACLForResource" wafv2 get-web-acl-for-resource \
    --resource-arn "arn:aws:elasticloadbalancing:${REGION}:000000000000:loadbalancer/app/probe/x"
  probe "ListResourcesForWebACL" wafv2 list-resources-for-web-acl --web-acl-arn "$WAF_ACL_ARN"
else
  for _a in "TagResource" "UntagResource" "ListTagsForResource" \
     "AssociateWebACL" "DisassociateWebACL" "GetWebACLForResource" "ListResourcesForWebACL"; do
    skip_probe "$_a" "no WAF ACL ARN"
  done
fi
probe "CheckCapacity"          wafv2 check-capacity --scope "$WAF_SCOPE" --rules '[]'
probe "DescribeManagedRuleGroup" wafv2 describe-managed-rule-group \
  --scope "$WAF_SCOPE" --vendor-name AWS --name AWSManagedRulesCommonRuleSet

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Instances & Images
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Instances & Images"
INSTANCE_JSON=$(A ec2 run-instances --image-id ami-00000000 --instance-type t2.micro \
  --min-count 1 --max-count 1 2>/dev/null || echo "")
INSTANCE_ID=$(echo "$INSTANCE_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['Instances'][0]['InstanceId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 terminate-instances --instance-ids '${INSTANCE_ID:-i-00000000}'")

probe "RunInstances"      ec2 run-instances --image-id ami-00000000 \
  --instance-type t2.micro --min-count 1 --max-count 1
probe "DescribeInstances"  ec2 describe-instances
probe "StopInstances"     ec2 stop-instances      --instance-ids "${INSTANCE_ID:-i-00000000}"
probe "StartInstances"    ec2 start-instances     --instance-ids "${INSTANCE_ID:-i-00000000}"
probe "RebootInstances"   ec2 reboot-instances    --instance-ids "${INSTANCE_ID:-i-00000000}"
probe "TerminateInstances" ec2 terminate-instances --instance-ids "${INSTANCE_ID:-i-00000000}"
probe "DescribeImages"    ec2 describe-images
probe "DescribeInstanceAttribute"  ec2 describe-instance-attribute \
  --instance-id "${INSTANCE_ID:-i-00000000}" --attribute instanceType
probe "DescribeInstanceTypes"  ec2 describe-instance-types
probe "DescribeInstanceCreditSpecifications" ec2 describe-instance-credit-specifications
probe "DescribeInstanceMaintenanceOptions"   ec2 describe-instance-maintenance-options \
  --instance-ids "${INSTANCE_ID:-i-00000000}"
probe "DescribeInstanceAutoRecoveryAttribute" ec2 describe-instance-auto-recovery-attribute \
  --instance-id "${INSTANCE_ID:-i-00000000}"
probe "ModifyInstanceMaintenanceOptions"     ec2 modify-instance-maintenance-options \
  --instance-id "${INSTANCE_ID:-i-00000000}" --auto-recovery default
probe "DescribeInstanceTopology"     ec2 describe-instance-topology
probe "DescribeSpotInstanceRequests" ec2 describe-spot-instance-requests
probe "DescribeCapacityReservations" ec2 describe-capacity-reservations
probe "DescribeAvailabilityZones"    ec2 describe-availability-zones
probe "DescribeTags / CreateTags / DeleteTags" ec2 describe-tags

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Security Groups
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Security Groups"
VPC_JSON=$(A ec2 create-vpc --cidr-block 10.99.0.0/16 2>/dev/null || echo "")
VPC_ID=$(echo "$VPC_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['Vpc']['VpcId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-vpc --vpc-id '${VPC_ID:-vpc-00000000}'")

SG_JSON=$(A ec2 create-security-group --group-name "probe-sg-${RUN_ID}" \
  --description "probe" --vpc-id "${VPC_ID:-vpc-00000000}" 2>/dev/null || echo "")
SG_ID=$(echo "$SG_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['GroupId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-security-group --group-id '${SG_ID:-sg-00000000}'")

probe "CreateSecurityGroup"  ec2 create-security-group \
  --group-name "probe-sg2-${RUN_ID}" --description "probe2" --vpc-id "${VPC_ID:-vpc-00000000}"
probe "DescribeSecurityGroups" ec2 describe-security-groups
probe "AuthorizeSecurityGroupIngress" ec2 authorize-security-group-ingress \
  --group-id "${SG_ID:-sg-00000000}" \
  --ip-permissions 'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]'
probe "DescribeSecurityGroupRules" ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=${SG_ID:-sg-00000000}"
probe "AuthorizeSecurityGroupEgress"  ec2 authorize-security-group-egress \
  --group-id "${SG_ID:-sg-00000000}" \
  --ip-permissions 'IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0}]'
probe "RevokeSecurityGroupIngress" ec2 revoke-security-group-ingress \
  --group-id "${SG_ID:-sg-00000000}" \
  --ip-permissions 'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]'
probe "RevokeSecurityGroupEgress" ec2 revoke-security-group-egress \
  --group-id "${SG_ID:-sg-00000000}" \
  --ip-permissions 'IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0}]'
probe "DeleteSecurityGroup" ec2 delete-security-group \
  --group-id "${SG_ID:-sg-00000000}"

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — VPC & Subnets
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — VPC & Subnets"
probe "CreateVpc"          ec2 create-vpc --cidr-block 10.100.0.0/16
probe "DeleteVpc"          ec2 delete-vpc --vpc-id "${VPC_ID:-vpc-00000000}"  # may fail = API exists
probe "DescribeVpcs"       ec2 describe-vpcs
probe "ModifyVpcAttribute" ec2 modify-vpc-attribute \
  --vpc-id "${VPC_ID:-vpc-00000000}" --enable-dns-support '{"Value":true}'
probe "DescribeVpcAttribute" ec2 describe-vpc-attribute \
  --vpc-id "${VPC_ID:-vpc-00000000}" --attribute enableDnsSupport
probe "DescribeVpcClassicLink" ec2 describe-vpc-classic-link \
  --vpc-ids "${VPC_ID:-vpc-00000000}"

SUBNET_JSON=$(A ec2 create-subnet --vpc-id "${VPC_ID:-vpc-00000000}" \
  --cidr-block 10.99.1.0/24 --availability-zone "${REGION}a" 2>/dev/null || echo "")
SUBNET_ID=$(echo "$SUBNET_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['Subnet']['SubnetId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-subnet --subnet-id '${SUBNET_ID:-subnet-00000000}'")

probe "CreateSubnet"         ec2 create-subnet --vpc-id "${VPC_ID:-vpc-00000000}" \
  --cidr-block 10.99.2.0/24 --availability-zone "${REGION}a"
probe "DeleteSubnet"         ec2 delete-subnet --subnet-id "${SUBNET_ID:-subnet-00000000}"
probe "DescribeSubnets"      ec2 describe-subnets
probe "ModifySubnetAttribute" ec2 modify-subnet-attribute \
  --subnet-id "${SUBNET_ID:-subnet-00000000}" --map-public-ip-on-launch

EP_JSON=$(A ec2 create-vpc-endpoint --vpc-id "${VPC_ID:-vpc-00000000}" \
  --service-name "com.amazonaws.${REGION}.s3" --vpc-endpoint-type Gateway 2>/dev/null || echo "")
VPC_EP_ID=$(echo "$EP_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['VpcEndpoint']['VpcEndpointId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-vpc-endpoints --vpc-endpoint-ids '${VPC_EP_ID:-vpce-00000000}'")

probe "CreateVpcEndpoint"    ec2 create-vpc-endpoint --vpc-id "${VPC_ID:-vpc-00000000}" \
  --service-name "com.amazonaws.${REGION}.s3" --vpc-endpoint-type Gateway
probe "DeleteVpcEndpoints"   ec2 delete-vpc-endpoints \
  --vpc-endpoint-ids "${VPC_EP_ID:-vpce-00000000}"
probe "DescribeVpcEndpoints" ec2 describe-vpc-endpoints
probe "ModifyVpcEndpoint"    ec2 modify-vpc-endpoint \
  --vpc-endpoint-id "${VPC_EP_ID:-vpce-00000000}"

PEER_JSON=$(A ec2 create-vpc-peering-connection \
  --vpc-id "${VPC_ID:-vpc-00000000}" \
  --peer-vpc-id "${VPC_ID:-vpc-00000000}" 2>/dev/null || echo "")
VPC_PEER_ID=$(echo "$PEER_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['VpcPeeringConnection']['VpcPeeringConnectionId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-vpc-peering-connection --vpc-peering-connection-id '${VPC_PEER_ID:-pcx-00000000}'")

probe "CreateVpcPeeringConnection"  ec2 create-vpc-peering-connection \
  --vpc-id "${VPC_ID:-vpc-00000000}" --peer-vpc-id "${VPC_ID:-vpc-00000000}"
probe "AcceptVpcPeeringConnection"  ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id "${VPC_PEER_ID:-pcx-00000000}"
probe "DescribeVpcPeeringConnections" ec2 describe-vpc-peering-connections
probe "DeleteVpcPeeringConnection"  ec2 delete-vpc-peering-connection \
  --vpc-peering-connection-id "${VPC_PEER_ID:-pcx-00000000}"

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Internet Gateway & Routing
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Internet Gateway & Routing"
IGW_JSON=$(A ec2 create-internet-gateway 2>/dev/null || echo "")
IGW_ID=$(echo "$IGW_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['InternetGateway']['InternetGatewayId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 detach-internet-gateway --internet-gateway-id '${IGW_ID:-igw-00000000}' --vpc-id '${VPC_ID:-vpc-00000000}'")
cleanup_fns+=("A ec2 delete-internet-gateway --internet-gateway-id '${IGW_ID:-igw-00000000}'")

probe "CreateInternetGateway"  ec2 create-internet-gateway
probe "DeleteInternetGateway"  ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID:-igw-00000000}"
probe "DescribeInternetGateways" ec2 describe-internet-gateways
probe "AttachInternetGateway"  ec2 attach-internet-gateway \
  --internet-gateway-id "${IGW_ID:-igw-00000000}" --vpc-id "${VPC_ID:-vpc-00000000}"
probe "DetachInternetGateway"  ec2 detach-internet-gateway \
  --internet-gateway-id "${IGW_ID:-igw-00000000}" --vpc-id "${VPC_ID:-vpc-00000000}"

RTB_JSON=$(A ec2 create-route-table --vpc-id "${VPC_ID:-vpc-00000000}" 2>/dev/null || echo "")
RTB_ID=$(echo "$RTB_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['RouteTable']['RouteTableId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-route-table --route-table-id '${RTB_ID:-rtb-00000000}'")

probe "CreateRouteTable"     ec2 create-route-table --vpc-id "${VPC_ID:-vpc-00000000}"
probe "DeleteRouteTable"     ec2 delete-route-table --route-table-id "${RTB_ID:-rtb-00000000}"
probe "DescribeRouteTables"  ec2 describe-route-tables

ASSOC_JSON=$(A ec2 associate-route-table \
  --route-table-id "${RTB_ID:-rtb-00000000}" \
  --subnet-id "${SUBNET_ID:-subnet-00000000}" 2>/dev/null || echo "")
ASSOC_ID=$(echo "$ASSOC_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['AssociationId'])" 2>/dev/null || echo "")

probe "AssociateRouteTable"  ec2 associate-route-table \
  --route-table-id "${RTB_ID:-rtb-00000000}" \
  --subnet-id "${SUBNET_ID:-subnet-00000000}"
probe "DisassociateRouteTable" ec2 disassociate-route-table \
  --association-id "${ASSOC_ID:-rtbassoc-00000000}"
probe "ReplaceRouteTableAssociation" ec2 replace-route-table-association \
  --association-id "${ASSOC_ID:-rtbassoc-00000000}" \
  --route-table-id "${RTB_ID:-rtb-00000000}"
probe "CreateRoute"  ec2 create-route \
  --route-table-id "${RTB_ID:-rtb-00000000}" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "${IGW_ID:-igw-00000000}"
probe "ReplaceRoute" ec2 replace-route \
  --route-table-id "${RTB_ID:-rtb-00000000}" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "${IGW_ID:-igw-00000000}"
probe "DeleteRoute"  ec2 delete-route \
  --route-table-id "${RTB_ID:-rtb-00000000}" --destination-cidr-block 0.0.0.0/0

EIP_JSON=$(A ec2 allocate-address --domain vpc 2>/dev/null || echo "")
EIP_ALLOC_ID=$(echo "$EIP_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['AllocationId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 release-address --allocation-id '${EIP_ALLOC_ID:-eipalloc-00000000}'")

NAT_JSON=$(A ec2 create-nat-gateway \
  --subnet-id "${SUBNET_ID:-subnet-00000000}" \
  --allocation-id "${EIP_ALLOC_ID:-eipalloc-00000000}" 2>/dev/null || echo "")
NAT_GW_ID=$(echo "$NAT_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['NatGateway']['NatGatewayId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-nat-gateway --nat-gateway-id '${NAT_GW_ID:-nat-00000000}'")

probe "CreateNatGateway"   ec2 create-nat-gateway \
  --subnet-id "${SUBNET_ID:-subnet-00000000}" \
  --allocation-id "${EIP_ALLOC_ID:-eipalloc-00000000}"
probe "DescribeNatGateways" ec2 describe-nat-gateways
probe "DeleteNatGateway"   ec2 delete-nat-gateway \
  --nat-gateway-id "${NAT_GW_ID:-nat-00000000}"

EOIGW_JSON=$(A ec2 create-egress-only-internet-gateway \
  --vpc-id "${VPC_ID:-vpc-00000000}" 2>/dev/null || echo "")
EOIGW_ID=$(echo "$EOIGW_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['EgressOnlyInternetGateway']['EgressOnlyInternetGatewayId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-egress-only-internet-gateway --egress-only-internet-gateway-id '${EOIGW_ID:-eigw-00000000}'")

probe "CreateEgressOnlyInternetGateway"   ec2 create-egress-only-internet-gateway \
  --vpc-id "${VPC_ID:-vpc-00000000}"
probe "DescribeEgressOnlyInternetGateways" ec2 describe-egress-only-internet-gateways
probe "DeleteEgressOnlyInternetGateway"   ec2 delete-egress-only-internet-gateway \
  --egress-only-internet-gateway-id "${EOIGW_ID:-eigw-00000000}"

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Elastic IPs
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Elastic IPs"
probe "AllocateAddress"   ec2 allocate-address --domain vpc
probe "ReleaseAddress"    ec2 release-address  --allocation-id "${EIP_ALLOC_ID:-eipalloc-00000000}"
probe "AssociateAddress"  ec2 associate-address \
  --allocation-id "${EIP_ALLOC_ID:-eipalloc-00000000}" \
  --instance-id "${INSTANCE_ID:-i-00000000}"
probe "DisassociateAddress" ec2 disassociate-address \
  --association-id "eipassoc-00000000"
probe "DescribeAddresses" ec2 describe-addresses
probe "DescribeAddressesAttribute" ec2 describe-addresses-attribute \
  --allocation-ids "${EIP_ALLOC_ID:-eipalloc-00000000}" --attribute domain

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Network Interfaces
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Network Interfaces"
ENI_JSON=$(A ec2 create-network-interface \
  --subnet-id "${SUBNET_ID:-subnet-00000000}" 2>/dev/null || echo "")
ENI_ID=$(echo "$ENI_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['NetworkInterface']['NetworkInterfaceId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-network-interface --network-interface-id '${ENI_ID:-eni-00000000}'")

probe "CreateNetworkInterface" ec2 create-network-interface \
  --subnet-id "${SUBNET_ID:-subnet-00000000}"
probe "DeleteNetworkInterface" ec2 delete-network-interface \
  --network-interface-id "${ENI_ID:-eni-00000000}"
probe "DescribeNetworkInterfaces" ec2 describe-network-interfaces
probe "AttachNetworkInterface" ec2 attach-network-interface \
  --network-interface-id "${ENI_ID:-eni-00000000}" \
  --instance-id "${INSTANCE_ID:-i-00000000}" --device-index 1
probe "DetachNetworkInterface" ec2 detach-network-interface \
  --attachment-id "eni-attach-00000000"

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Key Pairs
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Key Pairs"
A ec2 create-key-pair --key-name "$KP_NAME" > /dev/null 2>&1 || true
cleanup_fns+=("A ec2 delete-key-pair --key-name '$KP_NAME'")
probe "CreateKeyPair"       ec2 create-key-pair --key-name "${KP_NAME}-2"
probe "DeleteKeyPair"       ec2 delete-key-pair --key-name "${KP_NAME}-2"
probe "DescribeKeyPairs"    ec2 describe-key-pairs
probe "ImportKeyPair"       ec2 import-key-pair --key-name "${KP_NAME}-import" \
  --public-key-material "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFDNyBwcm9iZUBwcm9iZQo="

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Network ACLs & Flow Logs
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Network ACLs & Flow Logs"
NACL_JSON=$(A ec2 create-network-acl --vpc-id "${VPC_ID:-vpc-00000000}" 2>/dev/null || echo "")
NACL_ID=$(echo "$NACL_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['NetworkAcl']['NetworkAclId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-network-acl --network-acl-id '${NACL_ID:-acl-00000000}'")

IAM_FL_ROLE="arn:aws:iam::000000000000:role/${IAM_ROLE}"
LOG_GROUP="probe-fl-${RUN_ID}"
A logs create-log-group --log-group-name "$LOG_GROUP" > /dev/null 2>&1 || true
cleanup_fns+=("A logs delete-log-group --log-group-name '$LOG_GROUP'")

probe "CreateNetworkAcl"    ec2 create-network-acl --vpc-id "${VPC_ID:-vpc-00000000}"
probe "DescribeNetworkAcls" ec2 describe-network-acls
probe "DeleteNetworkAcl"    ec2 delete-network-acl --network-acl-id "${NACL_ID:-acl-00000000}"
probe "CreateNetworkAclEntry" ec2 create-network-acl-entry \
  --network-acl-id "${NACL_ID:-acl-00000000}" --rule-number 100 \
  --protocol tcp --port-range From=80,To=80 --cidr-block 0.0.0.0/0 --rule-action allow --ingress
probe "DeleteNetworkAclEntry" ec2 delete-network-acl-entry \
  --network-acl-id "${NACL_ID:-acl-00000000}" --rule-number 100 --ingress
probe "ReplaceNetworkAclEntry" ec2 replace-network-acl-entry \
  --network-acl-id "${NACL_ID:-acl-00000000}" --rule-number 100 \
  --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow --ingress
probe "ReplaceNetworkAclAssociation" ec2 replace-network-acl-association \
  --association-id "aclassoc-00000000" --network-acl-id "${NACL_ID:-acl-00000000}"

FL_JSON=$(A ec2 create-flow-logs \
  --resource-ids "${VPC_ID:-vpc-00000000}" --resource-type VPC \
  --traffic-type ALL --log-destination-type cloud-watch-logs \
  --log-group-name "$LOG_GROUP" \
  --deliver-logs-permission-arn "$IAM_FL_ROLE" 2>/dev/null || echo "")
FLOW_LOG_ID=$(echo "$FL_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); fl=d.get('FlowLogIds',[]); print(fl[0] if fl else '')" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-flow-logs --flow-log-ids '${FLOW_LOG_ID:-fl-00000000}'")

probe "CreateFlowLogs"   ec2 create-flow-logs \
  --resource-ids "${VPC_ID:-vpc-00000000}" --resource-type VPC \
  --traffic-type ALL --log-destination-type cloud-watch-logs \
  --log-group-name "$LOG_GROUP" \
  --deliver-logs-permission-arn "$IAM_FL_ROLE"
probe "DescribeFlowLogs" ec2 describe-flow-logs
probe "DeleteFlowLogs"   ec2 delete-flow-logs \
  --flow-log-ids "${FLOW_LOG_ID:-fl-00000000}"

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — DHCP
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — DHCP"
DHCP_JSON=$(A ec2 create-dhcp-options \
  --dhcp-configurations 'Key=domain-name,Values=probe.local' 2>/dev/null || echo "")
DHCP_ID=$(echo "$DHCP_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['DhcpOptions']['DhcpOptionsId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-dhcp-options --dhcp-options-id '${DHCP_ID:-dopt-00000000}'")

probe "CreateDhcpOptions"   ec2 create-dhcp-options \
  --dhcp-configurations 'Key=domain-name,Values=probe2.local'
probe "AssociateDhcpOptions" ec2 associate-dhcp-options \
  --vpc-id "${VPC_ID:-vpc-00000000}" --dhcp-options-id "${DHCP_ID:-dopt-00000000}"
probe "DescribeDhcpOptions"  ec2 describe-dhcp-options
probe "DeleteDhcpOptions"    ec2 delete-dhcp-options \
  --dhcp-options-id "${DHCP_ID:-dopt-00000000}"

# ═════════════════════════════════════════════════════════════════════════════
# EBS
# ═════════════════════════════════════════════════════════════════════════════
section "EBS"
VOL_JSON=$(A ec2 create-volume --availability-zone "${REGION}a" --size 1 \
  --volume-type gp2 2>/dev/null || echo "")
VOLUME_ID=$(echo "$VOL_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['VolumeId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-volume --volume-id '${VOLUME_ID:-vol-00000000}'")

probe "CreateVolume"           ec2 create-volume --availability-zone "${REGION}a" \
  --size 1 --volume-type gp2
probe "DeleteVolume"           ec2 delete-volume --volume-id "${VOLUME_ID:-vol-00000000}"
probe "DescribeVolumes"        ec2 describe-volumes
probe "DescribeVolumeStatus"   ec2 describe-volume-status
probe "AttachVolume"           ec2 attach-volume --volume-id "${VOLUME_ID:-vol-00000000}" \
  --instance-id "${INSTANCE_ID:-i-00000000}" --device /dev/sdf
probe "DetachVolume"           ec2 detach-volume --volume-id "${VOLUME_ID:-vol-00000000}"
probe "ModifyVolume"           ec2 modify-volume --volume-id "${VOLUME_ID:-vol-00000000}" --size 2
probe "DescribeVolumesModifications" ec2 describe-volumes-modifications

SNAP_JSON=$(A ec2 create-snapshot --volume-id "${VOLUME_ID:-vol-00000000}" \
  --description "probe" 2>/dev/null || echo "")
SNAP_ID=$(echo "$SNAP_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['SnapshotId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-snapshot --snapshot-id '${SNAP_ID:-snap-00000000}'")

probe "CreateSnapshot"       ec2 create-snapshot --volume-id "${VOLUME_ID:-vol-00000000}" \
  --description "probe"
probe "DeleteSnapshot"       ec2 delete-snapshot --snapshot-id "${SNAP_ID:-snap-00000000}"
probe "DescribeSnapshots"    ec2 describe-snapshots --owner-ids self
probe "CopySnapshot"         ec2 copy-snapshot \
  --source-region "$REGION" --source-snapshot-id "${SNAP_ID:-snap-00000000}"
probe "ModifySnapshotAttribute" ec2 modify-snapshot-attribute \
  --snapshot-id "${SNAP_ID:-snap-00000000}" --attribute createVolumePermission \
  --operation-type add --group-names all


# ═════════════════════════════════════════════════════════════════════════════
# Lambda
# ═════════════════════════════════════════════════════════════════════════════
section "Lambda"
# Create minimal Lambda zip
TMP_PY=$(mktemp /tmp/probe-handler-XXXXXX.py)
echo "def handler(e,c): return {'statusCode': 200}" > "$TMP_PY"
(cd "$(dirname $TMP_PY)" && zip -qj "$LAMBDA_ZIP" "$(basename $TMP_PY)") 2>/dev/null || true
rm -f "$TMP_PY"

FN_ROLE="arn:aws:iam::000000000000:role/${IAM_ROLE}"
A lambda create-function --function-name "$LAMBDA_NAME" \
  --runtime python3.12 --role "$FN_ROLE" \
  --handler "$(basename $TMP_PY .py).handler" \
  --zip-file "fileb://${LAMBDA_ZIP}" > /dev/null 2>&1 || true
LAMBDA_ARN=$(A lambda get-function --function-name "$LAMBDA_NAME" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['Configuration']['FunctionArn'])" 2>/dev/null || echo "")
cleanup_fns+=("A lambda delete-function --function-name '$LAMBDA_NAME'")

probe "CreateFunction"    lambda create-function --function-name "${LAMBDA_NAME}-2" \
  --runtime python3.12 --role "$FN_ROLE" --handler index.handler \
  --zip-file "fileb://${LAMBDA_ZIP}"
A lambda delete-function --function-name "${LAMBDA_NAME}-2" > /dev/null 2>&1 || true
probe "UpdateFunctionCode" lambda update-function-code \
  --function-name "$LAMBDA_NAME" --zip-file "fileb://${LAMBDA_ZIP}"
probe "UpdateFunctionConfiguration" lambda update-function-configuration \
  --function-name "$LAMBDA_NAME" --timeout 10
probe "GetFunction"       lambda get-function     --function-name "$LAMBDA_NAME"
probe "ListFunctions"     lambda list-functions
probe "DeleteFunction"    lambda delete-function  --function-name "${LAMBDA_NAME}-2"  # already gone

probe "PublishVersion"     lambda publish-version --function-name "$LAMBDA_NAME"
probe "ListVersionsByFunction" lambda list-versions-by-function --function-name "$LAMBDA_NAME"

probe "CreateFunctionUrlConfig" lambda create-function-url-config \
  --function-name "$LAMBDA_NAME" --auth-type NONE
probe "GetFunctionUrlConfig"    lambda get-function-url-config \
  --function-name "$LAMBDA_NAME"
probe "DeleteFunctionUrlConfig" lambda delete-function-url-config \
  --function-name "$LAMBDA_NAME"

ESM_JSON=$(A lambda create-event-source-mapping \
  --function-name "$LAMBDA_NAME" \
  --event-source-arn "arn:aws:sqs:${REGION}:000000000000:probe-queue" 2>/dev/null || echo "")
ESM_UUID=$(echo "$ESM_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['UUID'])" 2>/dev/null || echo "")
cleanup_fns+=("A lambda delete-event-source-mapping --uuid '${ESM_UUID:-00000000-0000-0000-0000-000000000000}'")

probe "CreateEventSourceMapping" lambda create-event-source-mapping \
  --function-name "$LAMBDA_NAME" \
  --event-source-arn "arn:aws:sqs:${REGION}:000000000000:probe-queue2"
probe "GetEventSourceMapping"    lambda get-event-source-mapping \
  --uuid "${ESM_UUID:-00000000-0000-0000-0000-000000000000}"
probe "ListEventSourceMappings"  lambda list-event-source-mappings \
  --function-name "$LAMBDA_NAME"
probe "UpdateEventSourceMapping" lambda update-event-source-mapping \
  --uuid "${ESM_UUID:-00000000-0000-0000-0000-000000000000}" --batch-size 5
probe "DeleteEventSourceMapping" lambda delete-event-source-mapping \
  --uuid "${ESM_UUID:-00000000-0000-0000-0000-000000000000}"

skip_probe "Node.js runtime support"    "behavioral (runtime execution)"
skip_probe "Python runtime support"     "behavioral (runtime execution)"
skip_probe "Provided runtime support"   "behavioral (runtime execution, Docker)"

probe "Invoke" lambda invoke --function-name "$LAMBDA_NAME" \
  --payload '{}' /tmp/lambda-out-${RUN_ID}.json
rm -f /tmp/lambda-out-${RUN_ID}.json 2>/dev/null || true

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — Prefix Lists & Managed Prefix Lists
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — Prefix Lists & Managed Prefix Lists"
PL_JSON=$(A ec2 create-managed-prefix-list --prefix-list-name "probe-pl-${RUN_ID}" \
  --max-entries 10 --address-family IPv4 2>/dev/null || echo "")
PREFIX_LIST_ID=$(echo "$PL_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['PrefixList']['PrefixListId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-managed-prefix-list --prefix-list-id '${PREFIX_LIST_ID:-pl-00000000}'")

probe "DescribePrefixLists"       ec2 describe-prefix-lists
probe "CreateManagedPrefixList"   ec2 create-managed-prefix-list \
  --prefix-list-name "probe-pl2-${RUN_ID}" --max-entries 5 --address-family IPv4
probe "DescribeManagedPrefixLists" ec2 describe-managed-prefix-lists
probe "GetManagedPrefixListEntries" ec2 get-managed-prefix-list-entries \
  --prefix-list-id "${PREFIX_LIST_ID:-pl-00000000}"
probe "ModifyManagedPrefixList"   ec2 modify-managed-prefix-list \
  --prefix-list-id "${PREFIX_LIST_ID:-pl-00000000}" \
  --add-entries Cidr=10.0.0.0/8,Description=probe --current-version 1
probe "DeleteManagedPrefixList"   ec2 delete-managed-prefix-list \
  --prefix-list-id "${PREFIX_LIST_ID:-pl-00000000}"

# ═════════════════════════════════════════════════════════════════════════════
# EC2 — VPN Gateways & Customer Gateways
# ═════════════════════════════════════════════════════════════════════════════
section "EC2 — VPN Gateways & Customer Gateways"
VGW_JSON=$(A ec2 create-vpn-gateway --type ipsec.1 2>/dev/null || echo "")
VPN_GW_ID=$(echo "$VGW_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['VpnGateway']['VpnGatewayId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 detach-vpn-gateway --vpn-gateway-id '${VPN_GW_ID:-vgw-00000000}' --vpc-id '${VPC_ID:-vpc-00000000}'")
cleanup_fns+=("A ec2 delete-vpn-gateway --vpn-gateway-id '${VPN_GW_ID:-vgw-00000000}'")

CGW_JSON=$(A ec2 create-customer-gateway --type ipsec.1 --bgp-asn 65000 \
  --ip-address 203.0.113.1 2>/dev/null || echo "")
CGW_ID=$(echo "$CGW_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['CustomerGateway']['CustomerGatewayId'])" 2>/dev/null || echo "")
cleanup_fns+=("A ec2 delete-customer-gateway --customer-gateway-id '${CGW_ID:-cgw-00000000}'")

probe "CreateVpnGateway"        ec2 create-vpn-gateway --type ipsec.1
probe "DescribeVpnGateways"     ec2 describe-vpn-gateways
probe "AttachVpnGateway"        ec2 attach-vpn-gateway \
  --vpn-gateway-id "${VPN_GW_ID:-vgw-00000000}" --vpc-id "${VPC_ID:-vpc-00000000}"
probe "DetachVpnGateway"        ec2 detach-vpn-gateway \
  --vpn-gateway-id "${VPN_GW_ID:-vgw-00000000}" --vpc-id "${VPC_ID:-vpc-00000000}"
probe "DeleteVpnGateway"        ec2 delete-vpn-gateway \
  --vpn-gateway-id "${VPN_GW_ID:-vgw-00000000}"
probe "EnableVgwRoutePropagation"  ec2 enable-vgw-route-propagation \
  --gateway-id "${VPN_GW_ID:-vgw-00000000}" --route-table-id "${RTB_ID:-rtb-00000000}"
probe "DisableVgwRoutePropagation" ec2 disable-vgw-route-propagation \
  --gateway-id "${VPN_GW_ID:-vgw-00000000}" --route-table-id "${RTB_ID:-rtb-00000000}"
probe "CreateCustomerGateway"   ec2 create-customer-gateway --type ipsec.1 \
  --bgp-asn 65001 --ip-address 203.0.113.2
probe "DescribeCustomerGateways" ec2 describe-customer-gateways
probe "DeleteCustomerGateway"   ec2 delete-customer-gateway \
  --customer-gateway-id "${CGW_ID:-cgw-00000000}"

# ═════════════════════════════════════════════════════════════════════════════
# CloudFront
# ═════════════════════════════════════════════════════════════════════════════
section "CloudFront"
CF_CONFIG=$(cat <<'EOF'
{"Origins":{"Quantity":1,"Items":[{"Id":"probe","DomainName":"probe.s3.amazonaws.com","S3OriginConfig":{"OriginAccessIdentity":""}}]},"DefaultCacheBehavior":{"TargetOriginId":"probe","ViewerProtocolPolicy":"redirect-to-https","ForwardedValues":{"QueryString":false,"Cookies":{"Forward":"none"}},"MinTTL":0},"Comment":"probe","Enabled":true,"CallerReference":"probe-ref-PLACEHOLDER"}
EOF
)
CF_CONFIG="${CF_CONFIG//PLACEHOLDER/${RUN_ID}}"
CF_JSON=$(A cloudfront create-distribution --distribution-config "$CF_CONFIG" 2>/dev/null || echo "")
CF_DIST_ID=$(echo "$CF_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['Distribution']['Id'])" 2>/dev/null || echo "")
CF_ETAG=$(echo "$CF_JSON"   | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('ETag','x'))" 2>/dev/null || echo "x")
cleanup_fns+=("A cloudfront delete-distribution --id '${CF_DIST_ID:-x}' --if-match '${CF_ETAG:-x}'")

probe "CreateDistribution" cloudfront create-distribution \
  --distribution-config "${CF_CONFIG//probe-ref-${RUN_ID}/probe-ref2-${RUN_ID}}"
probe "GetDistribution"       cloudfront get-distribution       --id "${CF_DIST_ID:-x}"
probe "GetDistributionConfig" cloudfront get-distribution-config --id "${CF_DIST_ID:-x}"
probe "ListDistributions"     cloudfront list-distributions
probe "UpdateDistribution"    cloudfront update-distribution \
  --id "${CF_DIST_ID:-x}" --if-match "${CF_ETAG:-x}" \
  --distribution-config "$CF_CONFIG"
probe "DeleteDistribution"    cloudfront delete-distribution \
  --id "${CF_DIST_ID:-x}" --if-match "${CF_ETAG:-x}"

INV_JSON=$(A cloudfront create-invalidation --distribution-id "${CF_DIST_ID:-x}" \
  --invalidation-batch "Paths={Quantity=1,Items=[/*]},CallerReference=probe-${RUN_ID}" 2>/dev/null || echo "")
INV_ID=$(echo "$INV_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['Invalidation']['Id'])" 2>/dev/null || echo "")

probe "CreateInvalidation" cloudfront create-invalidation \
  --distribution-id "${CF_DIST_ID:-x}" \
  --invalidation-batch "Paths={Quantity=1,Items=[/*]},CallerReference=probe2-${RUN_ID}"
probe "ListInvalidations" cloudfront list-invalidations --distribution-id "${CF_DIST_ID:-x}"
probe "GetInvalidation"   cloudfront get-invalidation \
  --distribution-id "${CF_DIST_ID:-x}" --id "${INV_ID:-x}"

# ═════════════════════════════════════════════════════════════════════════════
# ECR
# ═════════════════════════════════════════════════════════════════════════════
section "ECR"
A ecr create-repository --repository-name "$ECR_REPO" > /dev/null 2>&1 || true
cleanup_fns+=("A ecr delete-repository --repository-name '$ECR_REPO' --force")

probe "CreateRepository"      ecr create-repository --repository-name "${ECR_REPO}-2"
A ecr delete-repository --repository-name "${ECR_REPO}-2" --force > /dev/null 2>&1 || true
probe "DescribeRepositories"  ecr describe-repositories
probe "DeleteRepository"      ecr delete-repository --repository-name "${ECR_REPO}-2" --force
probe "ListImages"            ecr list-images --repository-name "$ECR_REPO"
probe "DescribeImages"        ecr describe-images --repository-name "$ECR_REPO"
probe "GetAuthorizationToken" ecr get-authorization-token
probe "BatchGetImage"         ecr batch-get-image \
  --repository-name "$ECR_REPO" \
  --image-ids imageTag=latest
probe "BatchDeleteImage"      ecr batch-delete-image \
  --repository-name "$ECR_REPO" \
  --image-ids imageTag=latest
probe "Lifecycle policies"    ecr put-lifecycle-policy \
  --repository-name "$ECR_REPO" \
  --lifecycle-policy-text '{"rules":[{"rulePriority":1,"selection":{"tagStatus":"untagged","countType":"imageCountMoreThan","countNumber":5},"action":{"type":"expire"}}]}'
probe "Repository policies"   ecr set-repository-policy \
  --repository-name "$ECR_REPO" \
  --policy-text '{"Version":"2012-10-17","Statement":[]}'
probe "Tags"                  ecr tag-resource \
  --resource-arn "arn:aws:ecr:${REGION}:000000000000:repository/${ECR_REPO}" \
  --tags Key=probe,Value=yes
probe "Layer upload flow"     ecr initiate-layer-upload --repository-name "$ECR_REPO"


# =============================================================================
# AppSync
# =============================================================================
section "AppSync"
AS_JSON=$(A appsync create-graphql-api --name "probe-api-${RUN_ID}" \
  --authentication-type API_KEY 2>/dev/null || echo "")
APPSYNC_ID=$(echo "$AS_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['graphqlApi']['apiId'])" 2>/dev/null || echo "")
cleanup_fns+=("A appsync delete-graphql-api --api-id '${APPSYNC_ID:-x}'")

probe "CreateGraphQLApi"  appsync create-graphql-api \
  --name "probe-api2-${RUN_ID}" --authentication-type API_KEY
probe "GetGraphQLApi"     appsync get-graphql-api --api-id "${APPSYNC_ID:-x}"
probe "ListGraphQLApis"   appsync list-graphql-apis
probe "UpdateGraphQLApi"  appsync update-graphql-api --api-id "${APPSYNC_ID:-x}" \
  --name "probe-api-${RUN_ID}-upd" --authentication-type API_KEY
probe "DeleteGraphQLApi"  appsync delete-graphql-api --api-id "does-not-exist"

AK_JSON=$(A appsync create-api-key --api-id "${APPSYNC_ID:-x}" 2>/dev/null || echo "")
APPSYNC_KEY_ID=$(echo "$AK_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['apiKey']['id'])" 2>/dev/null || echo "")
probe "CreateApiKey"  appsync create-api-key --api-id "${APPSYNC_ID:-x}"
probe "ListApiKeys"   appsync list-api-keys  --api-id "${APPSYNC_ID:-x}"
probe "DeleteApiKey"  appsync delete-api-key --api-id "${APPSYNC_ID:-x}" \
  --id "${APPSYNC_KEY_ID:-x}"

probe "CreateDataSource" appsync create-data-source --api-id "${APPSYNC_ID:-x}" \
  --name "ProbeDS" --type NONE
probe "GetDataSource"    appsync get-data-source    --api-id "${APPSYNC_ID:-x}" \
  --name "ProbeDS"
probe "ListDataSources"  appsync list-data-sources  --api-id "${APPSYNC_ID:-x}"
probe "DeleteDataSource" appsync delete-data-source --api-id "${APPSYNC_ID:-x}" \
  --name "ProbeDS"

probe "CreateType"  appsync create-type --api-id "${APPSYNC_ID:-x}" \
  --definition "type ProbeType { id: ID! }" --format SDL
probe "ListTypes"   appsync list-types --api-id "${APPSYNC_ID:-x}" --format SDL
probe "GetType"     appsync get-type   --api-id "${APPSYNC_ID:-x}" \
  --type-name "ProbeType" --format SDL

probe "TagResource (AppSync)" appsync tag-resource \
  --resource-arn "arn:aws:appsync:${REGION}:000000000000:apis/${APPSYNC_ID:-x}" \
  --tags probe=yes
probe "UntagResource (AppSync)" appsync untag-resource \
  --resource-arn "arn:aws:appsync:${REGION}:000000000000:apis/${APPSYNC_ID:-x}" \
  --tag-keys probe
probe "ListTagsForResource (AppSync)" appsync list-tags-for-resource \
  --resource-arn "arn:aws:appsync:${REGION}:000000000000:apis/${APPSYNC_ID:-x}"
skip_probe "CreateResolver" "requires type+data-source to be set up first"
skip_probe "GetResolver"    "requires resolver to exist"
skip_probe "ListResolvers"  "requires type to exist"
skip_probe "DeleteResolver" "requires resolver to exist"
skip_probe "GraphQL data plane" "requires full schema + data source setup"

# =============================================================================
# Cognito
# =============================================================================
section "Cognito"
POOL_JSON=$(A cognito-idp create-user-pool --pool-name "probe-pool-${RUN_ID}" 2>/dev/null || echo "")
COGNITO_POOL_ID=$(echo "$POOL_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['UserPool']['Id'])" 2>/dev/null || echo "")
cleanup_fns+=("A cognito-idp delete-user-pool --user-pool-id '${COGNITO_POOL_ID:-x}'")

probe "CreateUserPool" cognito-idp create-user-pool --pool-name "probe-pool2-${RUN_ID}"
probe "GetUserPool"    cognito-idp describe-user-pool --user-pool-id "${COGNITO_POOL_ID:-x}"
probe "ListUserPools"  cognito-idp list-user-pools --max-results 10
probe "UpdateUserPool" cognito-idp update-user-pool --user-pool-id "${COGNITO_POOL_ID:-x}"
probe "DeleteUserPool" cognito-idp delete-user-pool --user-pool-id "eu-west-1_doesnotexist"

CLIENT_JSON=$(A cognito-idp create-user-pool-client \
  --user-pool-id "${COGNITO_POOL_ID:-x}" --client-name "probe-client" 2>/dev/null || echo "")
COGNITO_CLIENT_ID=$(echo "$CLIENT_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['UserPoolClient']['ClientId'])" 2>/dev/null || echo "")
cleanup_fns+=("A cognito-idp delete-user-pool-client --user-pool-id '${COGNITO_POOL_ID:-x}' --client-id '${COGNITO_CLIENT_ID:-x}'")

probe "CreateUserPoolClient" cognito-idp create-user-pool-client \
  --user-pool-id "${COGNITO_POOL_ID:-x}" --client-name "probe-client2"
probe "GetUserPoolClient"    cognito-idp describe-user-pool-client \
  --user-pool-id "${COGNITO_POOL_ID:-x}" --client-id "${COGNITO_CLIENT_ID:-x}"
probe "ListUserPoolClients"  cognito-idp list-user-pool-clients \
  --user-pool-id "${COGNITO_POOL_ID:-x}"
probe "UpdateUserPoolClient" cognito-idp update-user-pool-client \
  --user-pool-id "${COGNITO_POOL_ID:-x}" --client-id "${COGNITO_CLIENT_ID:-x}"
probe "DeleteUserPoolClient" cognito-idp delete-user-pool-client \
  --user-pool-id "${COGNITO_POOL_ID:-x}" --client-id "doesnotexist"

ID_POOL_JSON=$(A cognito-identity create-identity-pool \
  --identity-pool-name "probe_pool_${RUN_ID}" \
  --allow-unauthenticated-identities 2>/dev/null || echo "")
IDPOOL_ID=$(echo "$ID_POOL_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['IdentityPoolId'])" 2>/dev/null || echo "")
cleanup_fns+=("A cognito-identity delete-identity-pool --identity-pool-id '${IDPOOL_ID:-x}'")

probe "CreateIdentityPool" cognito-identity create-identity-pool \
  --identity-pool-name "probe_pool2_${RUN_ID}" --allow-unauthenticated-identities
probe "GetIdentityPool"    cognito-identity describe-identity-pool \
  --identity-pool-id "${IDPOOL_ID:-x}"
probe "ListIdentityPools"  cognito-identity list-identity-pools --max-results 10
probe "UpdateIdentityPool" cognito-identity update-identity-pool \
  --identity-pool-id "${IDPOOL_ID:-x}" \
  --identity-pool-name "probe_pool_${RUN_ID}" --allow-unauthenticated-identities
probe "DeleteIdentityPool" cognito-identity delete-identity-pool \
  --identity-pool-id "x:doesnotexist"

probe "CreateUserPoolDomain" cognito-idp create-user-pool-domain \
  --domain "probe-dom-${RUN_ID}" --user-pool-id "${COGNITO_POOL_ID:-x}"
probe "GetUserPoolDomain"    cognito-idp describe-user-pool-domain \
  --domain "probe-dom-${RUN_ID}"
probe "DeleteUserPoolDomain" cognito-idp delete-user-pool-domain \
  --domain "probe-dom-${RUN_ID}" --user-pool-id "${COGNITO_POOL_ID:-x}"

probe "JWKS/OIDC endpoints" cognito-idp get-signing-certificate \
  --user-pool-id "${COGNITO_POOL_ID:-x}"

# =============================================================================
# KMS
# =============================================================================
section "KMS"
KMS_JSON=$(A kms create-key --description "probe-key-${RUN_ID}" 2>/dev/null || echo "")
KMS_KEY_ID=$(echo "$KMS_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['KeyMetadata']['KeyId'])" 2>/dev/null || echo "")
KMS_KEY_ARN=$(echo "$KMS_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['KeyMetadata']['Arn'])" 2>/dev/null || echo "")
cleanup_fns+=("A kms schedule-key-deletion --key-id '${KMS_KEY_ID:-x}' --pending-window-in-days 7")

probe "CreateKey"       kms create-key --description "probe-key2-${RUN_ID}"
probe "DescribeKey"     kms describe-key --key-id "${KMS_KEY_ID:-x}"
probe "ListKeys"        kms list-keys
probe "ScheduleKeyDeletion" kms schedule-key-deletion \
  --key-id "${KMS_KEY_ID:-x}" --pending-window-in-days 7
probe "CancelKeyDeletion" kms cancel-key-deletion --key-id "${KMS_KEY_ID:-x}"
probe "EnableKey"       kms enable-key   --key-id "${KMS_KEY_ID:-x}"
probe "DisableKey"      kms disable-key  --key-id "${KMS_KEY_ID:-x}"
probe "EnableKeyRotation"  kms enable-key-rotation  --key-id "${KMS_KEY_ID:-x}"
probe "DisableKeyRotation" kms disable-key-rotation --key-id "${KMS_KEY_ID:-x}"
probe "GetKeyRotationStatus" kms get-key-rotation-status --key-id "${KMS_KEY_ID:-x}"
probe "PutKeyPolicy"   kms put-key-policy --key-id "${KMS_KEY_ID:-x}" \
  --policy-name default \
  --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"kms:*","Resource":"*"}]}'
probe "GetKeyPolicy"   kms get-key-policy --key-id "${KMS_KEY_ID:-x}" --policy-name default
probe "ListKeyPolicies" kms list-key-policies --key-id "${KMS_KEY_ID:-x}"
probe "TagResource (KMS)" kms tag-resource --key-id "${KMS_KEY_ID:-x}" \
  --tags TagKey=probe,TagValue=yes
probe "UntagResource (KMS)" kms untag-resource --key-id "${KMS_KEY_ID:-x}" \
  --tag-keys probe
probe "ListResourceTags" kms list-resource-tags --key-id "${KMS_KEY_ID:-x}"

KMS_CIPHERTEXT=$(A kms enable-key --key-id "${KMS_KEY_ID:-x}" > /dev/null 2>&1;
  A kms encrypt --key-id "${KMS_KEY_ID:-x}" --plaintext "aGVsbG8=" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['CiphertextBlob'])" 2>/dev/null || echo "aGVsbG8=")
probe "Encrypt"    kms encrypt --key-id "${KMS_KEY_ID:-x}" --plaintext "aGVsbG8="
probe "Decrypt"    kms decrypt --key-id "${KMS_KEY_ID:-x}" \
  --ciphertext-blob "${KMS_CIPHERTEXT:-aGVsbG8=}"
probe "GenerateDataKey" kms generate-data-key \
  --key-id "${KMS_KEY_ID:-x}" --key-spec AES_256
probe "GenerateDataKeyWithoutPlaintext" kms generate-data-key-without-plaintext \
  --key-id "${KMS_KEY_ID:-x}" --key-spec AES_256

RSA_JSON=$(A kms create-key --key-spec RSA_2048 \
  --key-usage SIGN_VERIFY --description "probe-rsa-${RUN_ID}" 2>/dev/null || echo "")
RSA_KEY_ID=$(echo "$RSA_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['KeyMetadata']['KeyId'])" 2>/dev/null || echo "")
cleanup_fns+=("A kms schedule-key-deletion --key-id '${RSA_KEY_ID:-x}' --pending-window-in-days 7")

MSG_B64=$(echo -n "hello" | base64)
SIG_JSON=$(A kms sign --key-id "${RSA_KEY_ID:-x}" --message "${MSG_B64}" \
  --message-type RAW --signing-algorithm RSASSA_PKCS1_V1_5_SHA_256 2>/dev/null || echo "")
SIG=$(echo "$SIG_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['Signature'])" 2>/dev/null || echo "")

probe "Sign"       kms sign --key-id "${RSA_KEY_ID:-x}" \
  --message "${MSG_B64}" --message-type RAW \
  --signing-algorithm RSASSA_PKCS1_V1_5_SHA_256
probe "Verify"     kms verify --key-id "${RSA_KEY_ID:-x}" \
  --message "${MSG_B64}" --message-type RAW \
  --signature "${SIG:-aGVsbG8=}" \
  --signing-algorithm RSASSA_PKCS1_V1_5_SHA_256
probe "GetPublicKey" kms get-public-key --key-id "${RSA_KEY_ID:-x}"

# =============================================================================
# Route53
# =============================================================================
section "Route53"
HZ_JSON=$(A route53 create-hosted-zone \
  --name "probe-${RUN_ID}.example.com" \
  --caller-reference "probe-${RUN_ID}" 2>/dev/null || echo "")
HOSTED_ZONE_ID=$(echo "$HZ_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['HostedZone']['Id'].split('/')[-1])" 2>/dev/null || echo "")
cleanup_fns+=("A route53 delete-hosted-zone --id '${HOSTED_ZONE_ID:-x}'")

probe "CreateHostedZone" route53 create-hosted-zone \
  --name "probe2-${RUN_ID}.example.com" --caller-reference "probe2-${RUN_ID}"
probe "GetHostedZone"    route53 get-hosted-zone --id "${HOSTED_ZONE_ID:-x}"
probe "ListHostedZones"  route53 list-hosted-zones
probe "DeleteHostedZone" route53 delete-hosted-zone --id "does-not-exist"

BATCH="{\"Changes\":[{\"Action\":\"CREATE\",\"ResourceRecordSet\":{\"Name\":\"probe.probe-${RUN_ID}.example.com\",\"Type\":\"A\",\"TTL\":60,\"ResourceRecords\":[{\"Value\":\"1.2.3.4\"}]}}]}"
CHANGE_JSON=$(A route53 change-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID:-x}" --change-batch "$BATCH" 2>/dev/null || echo "")
CHANGE_ID=$(echo "$CHANGE_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['ChangeInfo']['Id'].split('/')[-1])" 2>/dev/null || echo "")

probe "ChangeResourceRecordSets" route53 change-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID:-x}" --change-batch "$BATCH"
probe "ListResourceRecordSets"   route53 list-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID:-x}"
probe "GetChange" route53 get-change --id "${CHANGE_ID:-x}"

HC_JSON=$(A route53 create-health-check \
  --caller-reference "probe-hc-${RUN_ID}" \
  --health-check-config "Type=HTTP,ResourcePath=/,FullyQualifiedDomainName=probe.example.com,Port=80" 2>/dev/null || echo "")
HC_ID=$(echo "$HC_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['HealthCheck']['Id'])" 2>/dev/null || echo "")
cleanup_fns+=("A route53 delete-health-check --health-check-id '${HC_ID:-x}'")

probe "CreateHealthCheck" route53 create-health-check \
  --caller-reference "probe-hc2-${RUN_ID}" \
  --health-check-config "Type=HTTP,ResourcePath=/,FullyQualifiedDomainName=probe2.example.com,Port=80"
probe "GetHealthCheck"    route53 get-health-check --health-check-id "${HC_ID:-x}"
probe "ListHealthChecks"  route53 list-health-checks
probe "UpdateHealthCheck" route53 update-health-check --health-check-id "${HC_ID:-x}" \
  --health-check-version 1
probe "DeleteHealthCheck" route53 delete-health-check --health-check-id "does-not-exist"

# =============================================================================
# REPORT
# =============================================================================
PASS_COUNT=${#PASS_LIST[@]}
FAIL_COUNT=${#FAIL_LIST[@]}
SKIP_COUNT=${#SKIP_LIST[@]}
TOTAL=$(( PASS_COUNT + FAIL_COUNT + SKIP_COUNT ))

echo ""
echo "══════════════════════════════════════════════"
echo "  SUMMARY"
echo "══════════════════════════════════════════════"
printf "  %-8s %d/%d\n" "PASS"  "$PASS_COUNT" "$TOTAL"
printf "  %-8s %d/%d\n" "FAIL"  "$FAIL_COUNT" "$TOTAL"
printf "  %-8s %d/%d\n" "SKIP"  "$SKIP_COUNT" "$TOTAL"
echo ""

if [ ${#FAIL_LIST[@]} -gt 0 ]; then
  echo "FAILED APIs:"
  for entry in "${FAIL_LIST[@]}"; do
    IFS='|' read -r sec api <<< "$entry"
    printf "  %-40s %s\n" "$sec" "$api"
  done
  echo ""
fi

# Write markdown report
cat > "$REPORT_FILE" << REPORT_EOF
# MiniStack API Validation Report

> **Generated:** ${TS}
> **MiniStack version:** ${MS_VER}
> **Endpoint:** ${ENDPOINT}

## Summary

| Status | Count |
|--------|-------|
| ✅ PASS | ${PASS_COUNT} |
| ❌ FAIL | ${FAIL_COUNT} |
| ⚠️ SKIP | ${SKIP_COUNT} |
| **Total** | **${TOTAL}** |

REPORT_EOF

if [ ${#FAIL_LIST[@]} -gt 0 ]; then
  echo "## Failed APIs" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "| Section | API |" >> "$REPORT_FILE"
  echo "|---------|-----|" >> "$REPORT_FILE"
  for entry in "${FAIL_LIST[@]}"; do
    IFS='|' read -r sec api <<< "$entry"
    echo "| ${sec} | \`${api}\` |" >> "$REPORT_FILE"
  done
  echo "" >> "$REPORT_FILE"
fi

if [ ${#SKIP_LIST[@]} -gt 0 ]; then
  echo "## Skipped" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "| Section | API | Reason |" >> "$REPORT_FILE"
  echo "|---------|-----|--------|" >> "$REPORT_FILE"
  for entry in "${SKIP_LIST[@]}"; do
    IFS='|' read -r sec api reason <<< "$entry"
    echo "| ${sec} | \`${api}\` | ${reason} |" >> "$REPORT_FILE"
  done
  echo "" >> "$REPORT_FILE"
fi

echo "## Full Results" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
PREV_SEC=""
for entry in "${PASS_LIST[@]}" "${FAIL_LIST[@]}"; do
  IFS='|' read -r sec api <<< "$entry"
  if [ "$sec" != "$PREV_SEC" ]; then
    echo "### ${sec}" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| API | Status |" >> "$REPORT_FILE"
    echo "|-----|--------|" >> "$REPORT_FILE"
    PREV_SEC="$sec"
  fi
  STATUS="✅ PASS"
  for f in "${FAIL_LIST[@]:-}"; do
    if [[ "$f" == "${sec}|${api}" ]]; then STATUS="❌ FAIL"; fi
  done
  echo "| \`${api}\` | ${STATUS} |" >> "$REPORT_FILE"
done

echo "Report written to: $REPORT_FILE"
echo ""
echo "══════════════════════════════════════════════"
[ $FAIL_COUNT -eq 0 ] && echo "  All probes PASSED!" || echo "  ${FAIL_COUNT} probe(s) FAILED — see report"
echo "══════════════════════════════════════════════"
[ $FAIL_COUNT -eq 0 ] && exit 0 || exit 1
