# opa_runner.py

import subprocess
import json
import sys
import os

# --- Configuration ---
# Path to the Terraform JSON plan file (must be relative to repo root)
PLAN_JSON_PATH = "environments/dev/aws/tfplan.json"
# Path to your Rego policies
POLICY_DIR = "policies/rego"
# OPA Query to execute
OPA_QUERY = "data.terraform.analysis.deny"
# ---------------------

def run_opa_check():
    """Reads the JSON plan and runs the OPA check."""
    
    # 1. Check if the plan file exists
    if not os.path.exists(PLAN_JSON_PATH):
        print(f" ERROR: Plan file ({PLAN_JSON_PATH}) not found.")
        print("Please ensure you run 'terraform plan' and generate 'tfplan.json' before committing.")
        return 1

    print("Running OPA Policy Check via Python...")

    # 2. Build the OPA command (using the plan file as input)
    opa_command = [
        "opa", "eval", 
        "--data", POLICY_DIR, 
        "--input", PLAN_JSON_PATH,
        OPA_QUERY, 
        "--format", "json"
    ]

    # 3. Execute the OPA command (DO NOT use check=True)
    try:
        # Use check=False so OPA's non-zero exit code (2 for violations) doesn't raise an exception.
        # We rely only on stdout/JSON content to determine success/failure.
        result = subprocess.run(opa_command, capture_output=True, text=True, check=False, encoding='utf-8')
        violations_output = result.stdout.strip()
    
    except Exception as e:
        print(f" CRITICAL PYTHON ERROR during execution: {e}")
        return 1
    
    # Check if OPA failed to run (e.g., policy path error, status 1, 3, etc.)
    if result.returncode != 0 and result.returncode != 2: # 0=Pass, 2=Violations Found
        print(f" CRITICAL OPA EXECUTION ERROR (Exit Code {result.returncode}). Stderr:")
        print(result.stderr)
        return 1
    
    # 4. Check OPA Output (Reliably parse the JSON structure)
    try:
        data = json.loads(violations_output)
        
        # Access the list of results via 'result' key, which is present in your output.
        # This is the path: data['result'][0]['expressions'][0]['value']
        actual_violations = data['result'][0]['expressions'][0]['value']
        
    except (json.JSONDecodeError, IndexError, KeyError):
        # This block should only trigger if the output is NOT the standard OPA JSON structure.
        print(f"ERROR: Failed to parse OPA JSON output.")
        print(f"Raw OPA Output: {violations_output}")
        return 1


    # 5. Determine Policy Status based on the list content
    if len(actual_violations) == 0:
            print(" OPA Policy Check PASSED. Infrastructure is compliant.")
            return 0
    else:
            print(" OPA Policy Check FAILED! Violations found:")
            print(json.dumps(actual_violations, indent=2))
            return 1

if __name__ == "__main__":
    sys.exit(run_opa_check())