
🛡️ sec-iac: Secure Multi-Cloud Infrastructure as CodeThis repository provides secure, reusable Infrastructure-as-Code (IaC) configurations for AWS and Azure, managed by Terraform and validated by a Checkov-enabled CI/CD pipeline (GitHub Actions). The primary goal is to deploy standardized, secure infrastructure resources across multiple cloud environments.

✨ Key FeaturesMulti-Cloud Support: Configurations for deploying core networking and compute resources on AWS and Azure.Security Scanning: Automated security and compliance checks using Checkov to enforce policies before deployment.Modular Design: Infrastructure components (e.g., networking, compute) are built into reusable Terraform modules.GitHub Actions CI/CD: A pipeline for terraform fmt, terraform validate, and Checkov scanning on every change.Secure Defaults: Enforces security best practices like encryption, restricted network access, and least-privilege principles by default.

📂 Repository StructureThe code is organized by cloud provider for clear separation of concerns..
├───.github
│   └───workflows       # GitHub Actions workflow for plan, validate, and checkov scan
└───environments
    └───dev
        ├───aws         # Root configuration for AWS deployment
        └───azure       # Root configuration for Azure deployment

### 🚀 Getting Started

To deploy, you will need **Terraform** (v1.0+), **AWS CLI**, and **Azure CLI** installed and configured with appropriate credentials.

#### **1. Prerequisites**

* **Install Tools:** Terraform, AWS CLI, Azure CLI.
* **Authenticate AWS:** Ensure your AWS CLI is configured (e.g., using `aws configure`).
* **Authenticate Azure:** Log in using the Azure CLI:
    ```sh
    az login
    ```

#### **2. AWS Deployment**

Navigate to the AWS directory for deployment.

1.  Initialize Terraform:
    ```sh
    cd aws
    terraform init
    ```
2.  Review the Plan:
    ```sh
    # Replace [REGION] with your target region (e.g., us-east-1)
    terraform plan -var="region=[REGION]"
    ```
3.  Apply Changes:
    ```sh
    terraform apply -var="region=[REGION]"
    ```
    * **What is deployed?** *A secure VPC with private subnets, an EC2 instance in a private subnet, and tightly scoped Security Groups.* 

#### **3. Azure Deployment**

Navigate to the Azure directory for deployment.

1.  Initialize Terraform:
    ```sh
    cd azure
    terraform init
    ```
2.  Review the Plan:
    ```sh
    # Replace [LOCATION] with your target location (e.g., eastus)
    terraform plan -var="location=[LOCATION]"
    ```
3.  Apply Changes:
    ```sh
    terraform apply -var="location=[LOCATION]"
    ```
    * **What is deployed?** *A Virtual Network (VNet) with segmented subnets, an Azure Virtual Machine, and Network Security Groups (NSGs) for firewall control.* 

---

### 🔒 Security & Compliance

The primary security mechanism is the **Checkov** scanning integration within the CI pipeline.

| Security Control | Cloud Provider | Enforcement/Tool |
| :--- | :--- | :--- |
| **Network Isolation** | AWS/Azure | Uses private/internal subnets by default, minimal public IPs. |
| **Secure Group Rules** | AWS/Azure | Security Groups/NSGs are restrictive, disallowing public SSH/RDP (port 22/3389). |
| **Configuration Scan** | Multi-Cloud | **Checkov** runs on every PR to prevent insecure configurations from being merged. |
| **Encryption** | AWS | Enforces **KMS** encryption for storage resources (e.g., S3, EBS). |
| **Access Control** | AWS/Azure | Utilizes **IAM** roles and **RBAC** for least-privilege access. |

---

### 🗑️ Cleanup

To avoid unexpected cloud costs, remember to destroy your resources when finished.

* **AWS Cleanup:**
    ```sh
    cd aws
    terraform destroy -var="region=[REGION]"
    ```
* **Azure Cleanup:**
    ```sh
    cd azure
    terraform destroy -var="location=[LOCATION]"
    ```



🛡️ Policy as Code (OPA / Rego)
This environment uses Open Policy Agent (OPA) to enforce security guardrails. The policies are written in Rego and are located in the policies/rego directory.

✅ Key Policies Enforced
Public Access Prevention: Ensures S3 buckets and security groups do not have "open to world" (0.0.0.0/0) configurations.

Encryption Standards: Mandates that all EBS volumes and S3 buckets use AES256 or KMS encryption.

Tagging Compliance: Requires mandatory tags (e.g., Environment, Owner) on all trackable resources.

IAM Least Privilege: Scans for wildcard * permissions in IAM policies to prevent over-privileged roles.

🔍 How to Run Policy Checks
To validate your Terraform plan against these policies, follow these steps:

Generate a Plan in JSON format:

Bash

terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
Evaluate using OPA:

Bash

# Run OPA evaluation against the rego directory
opa eval --input tfplan.json --data policies/rego/ "data.terraform.policies.deny"
Using Conftest (Optional but Recommended): If you have conftest installed, you can run a more streamlined check:

Bash

conftest test tfplan.json -p policies/rego/
