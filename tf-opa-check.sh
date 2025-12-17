#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel)
if [[ $(uname) == MINGW* ]]; then
    PROJECT_ROOT=$(cygpath -u "$PROJECT_ROOT")
fi

TARGET_ENV=${1:-"aws"}
TF_DIR="$PROJECT_ROOT/environments/dev/$TARGET_ENV"
POLICY_DIR="$PROJECT_ROOT/policies/rego"
PLAN_BINARY="$TF_DIR/plan.tfplan"
PLAN_JSON="$TF_DIR/tfplan.json"
OPA_QUERY="data.terraform.analysis.deny"

echo "--- 🛡️ Starting OPA Policy Check for $TARGET_ENV ---"

cd "$TF_DIR"

# 1. Generate Plan
terraform init -backend=false > /dev/null 2>&1
terraform plan -out="$PLAN_BINARY" > /dev/null 2>&1
terraform show -json "$PLAN_BINARY" > "$PLAN_JSON"

# 2. Run OPA
VIOLATIONS=$(opa eval --data "$POLICY_DIR" --input "$PLAN_JSON" "$OPA_QUERY" --format json)

# 3. Clean up immediately so pre-commit doesn't think files were "modified"
rm -f "$PLAN_BINARY" "$PLAN_JSON"

# 4. Logic to check if "value" is empty []
# This checks if the result contains any denied items
IF_VIOLATION=$(echo "$VIOLATIONS" | grep -o '"value":\[[^]]' || true)

if [ -z "$IF_VIOLATION" ]; then
    echo "✅ SUCCESS: No policy violations found."
    exit 0
else
    echo "🛑 FAILURE: Policy violations found!"
    if command -v jq &> /dev/null; then
        echo "$VIOLATIONS" | jq '.result[0].expressions[0].value'
    else
        echo "$VIOLATIONS"
    fi
    exit 1
fi