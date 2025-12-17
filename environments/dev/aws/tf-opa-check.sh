#!/bin/bash
# Script to run OPA policy check against a pre-generated plan (Fallback for Windows Pathing issues)

set -e

TF_DIR="environments/dev/aws"
PLAN_JSON_PATH="$TF_DIR/tfplan.json"
POLICY_DIR="policies/rego"
OPA_QUERY="data.terraform.analysis.deny"

echo "Running OPA Policy Check against pre-generated plan file..."

# CRITICAL: Check if the JSON plan file exists
if [ ! -f "$PLAN_JSON_PATH" ]; then
    echo "🛑 ERROR: Plan file ($PLAN_JSON_PATH) not found."
    echo "Please run 'terraform plan -out tfplan.binary' and 'terraform show -json tfplan.binary > tfplan.json' manually before committing."
    exit 1
fi

# 1. Pipe the JSON plan directly to OPA (using < redirection for stability)
VIOLATIONS=$(bash -c "cat '$PLAN_JSON_PATH' | opa eval --data '$POLICY_DIR' --input - '$OPA_QUERY' --format json")

# 2. Clean up the temporary plan file
rm "$PLAN_JSON_PATH"

# 3. Check OPA Output
if [ "$VIOLATIONS" == "[]" ]; then
    echo "✅ OPA Policy Check PASSED. Infrastructure is compliant."
    exit 0
else
    echo "🛑 OPA Policy Check FAILED! Violations found:"
    echo "$VIOLATIONS" | jq .
    exit 1
fi

