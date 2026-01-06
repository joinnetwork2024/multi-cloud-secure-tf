# 🛡️ sec-iac — AI-First Security Governance & Policy-as-Code

[![Security Scan: Checkov](https://img.shields.io/badge/security-checkov-brightgreen)](https://github.com/bridgecrewio/checkov)
[![Policy Engine: OPA](https://img.shields.io/badge/policy-OPA%2FRego-blue)](https://www.openpolicyagent.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🚀 Overview

**sec-iac** is an **AI-first security governance engine** built on Infrastructure-as-Code (IaC) and Policy-as-Code principles. It enforces security, compliance, and governance controls *before* cloud resources are deployed—specifically tailored for **AI/ML workloads** across AWS and Azure.

Originally created as a secure multi-cloud landing zone, this repository has evolved to focus on **AI/ML security guardrails**, ensuring that model training, data handling, and execution environments comply with organizational and regulatory requirements from day one.

> **Project Architecture**
>
> * **sec-iac** → *The Brain*: security policies, governance rules, and compliance logic
> * **multi-cloud-secure-tf** → *The Body*: foundational infrastructure modules
>
> 👉 Use this repository together with [multi-cloud-secure-tf](https://github.com/joinnetwork2024/multi-cloud-secure-tf) for end-to-end secure deployments.

---

## 🎯 What This Project Solves

AI/ML workloads introduce unique risks that traditional cloud security controls do not fully address. **sec-iac** enforces guardrails that prevent insecure or non-compliant AI infrastructure from ever being provisioned.

This includes:

* Preventing model training in disallowed regions
* Enforcing isolation of inference endpoints
* Restricting access to training data and model artifacts
* Ensuring least-privilege execution roles for AI services

---

## ✨ Key Features

### 🧠 AI/ML Security Governance

* **Data Residency Enforcement**
  OPA/Rego policies ensure sensitive training and inference data remains within approved geographic regions.

* **Model & Endpoint Isolation**
  Network-level isolation for Amazon SageMaker and Azure ML endpoints to reduce data exfiltration risk.

* **Least-Privilege AI Roles**
  Fine-grained IAM (AWS) and RBAC (Azure) policies scoped specifically for AI execution, training, and model registry access.

### 🔐 Shift-Left Security

* **Pre-Deployment Enforcement** using:

  * Checkov
  * Open Policy Agent (OPA/Rego)
  * Terraform validation and linting

* **CI/CD Guardrails**
  Misconfigured or non-compliant infrastructure is blocked during pull requests—*before* reaching production.

### 🧩 Modular & Cloud-Agnostic Design

* Hardened Terraform modules optimized for:

  * GPU-heavy workloads
  * Private networking
  * Encrypted storage and secrets

---

## 📂 Repository Structure

The repository is organized by cloud provider with a centralized policy layer:

```text
├── .github/workflows       # GitHub Actions: Plan, Validate, Checkov
├── environments
│   └── dev
│       ├── aws             # Secure AWS AI infrastructure (SageMaker, VPC, EC2)
│       └── azure           # Secure Azure AI infrastructure (Azure ML, VNet, VM)
└── policies
    └── rego                # Custom OPA/Rego policies for AI governance
```

---

## 🔄 Project Evolution

This repository began as a general-purpose **secure multi-cloud IaC framework** for AWS and Azure, emphasizing compliance scanning and standardized deployments.

As AI/ML workloads became central to modern platforms, the project pivoted to focus on **AI-specific security and governance**, extending the original IaC foundation with:

* AI-aware compliance policies
* Model and data isolation requirements
* AI execution identity controls

This evolution allows teams to adopt the repository at different maturity levels—from general cloud security to advanced AI governance.

---

## 🚀 Getting Started

### Prerequisites

* Terraform **v1.0+**
* AWS CLI (configured credentials)
* Azure CLI (configured credentials)

### Example: AWS Deployment

```bash
cd environments/dev/aws
terraform init
terraform plan -var="aws_region=<REGION>"
terraform apply -var="aws_region=<REGION>"
```

Azure deployments follow the same pattern under `environments/dev/azure`.

---



# Documentation Update: Project Evolution & Navigation

## Purpose

This documentation update clarifies the **intentional evolution** of the `multi-cloud-secure-tf` and `sec-iac` repositories and provides clear guidance on how they work together. The goal is to make project navigation intuitive for readers discovering either repository or internal Notion documentation.

---

## 1️⃣ High-Level Architecture & Intent

These two repositories are designed to work together but serve **distinct, deliberate roles**:

| Repository                | Role                                          | Primary Focus                                  |
| ------------------------- | --------------------------------------------- | ---------------------------------------------- |
| **multi-cloud-secure-tf** | 🧱 *Infrastructure Foundation ("The Body")*   | Secure, reusable multi-cloud Terraform modules |
| **sec-iac**               | 🧠 *Security Governance Engine ("The Brain")* | AI/ML security, compliance, and policy-as-code |

This separation enables teams to adopt **secure infrastructure first**, then progressively enforce **advanced AI/ML governance** without refactoring core cloud foundations.

---

## 2️⃣ Project Evolution Narrative (Use in Notion & READMEs)

### Original State: Secure Multi-Cloud IaC

The project initially focused on providing **secure-by-default Infrastructure-as-Code** for AWS and Azure using Terraform. Core objectives included:

* Standardized VPC/VNet and compute deployments
* Encryption, network isolation, and least-privilege defaults
* Automated security scanning with Checkov and CI/CD pipelines

This foundation now lives primarily in **`multi-cloud-secure-tf`**.

---

### Intentional Pivot: AI/ML Security Governance

As AI and machine learning workloads became central to modern platforms, traditional cloud security patterns proved insufficient. AI workloads introduce new risks such as:

* Sensitive training data locality
* Model exfiltration via public endpoints
* Over-privileged execution roles
* Lack of policy enforcement before provisioning

To address these gaps, the project intentionally evolved toward **AI/ML-first security governance**, resulting in the creation and focus of **`sec-iac`**.

This pivot was *not* a rewrite—but a **layered extension** of the original secure IaC foundation.

---

## 3️⃣ Repository Responsibilities (Clear Separation of Concerns)

### 🧱 multi-cloud-secure-tf (Infrastructure Foundation)

**Purpose**: Provide hardened, reusable Terraform modules for AWS and Azure.

**Responsibilities**:

* Core networking (VPCs, VNets, subnets)
* Secure compute and base services
* Encryption, logging, and baseline compliance
* Cloud-agnostic structure for portability

**What it does *not* focus on**:

* AI/ML-specific compliance logic
* Data residency enforcement
* Model-level governance

👉 Think of this repository as the **secure platform substrate**.

---

### 🧠 sec-iac (AI/ML Security Governance)

**Purpose**: Enforce **policy-as-code guardrails** for AI/ML workloads *before* infrastructure is deployed.

**Responsibilities**:

* AI/ML data residency enforcement
* Model training and inference isolation
* Least-privilege IAM/RBAC for AI services
* OPA/Rego policies and Checkov enforcement
* Shift-left governance in CI/CD pipelines

👉 Think of this repository as the **decision-making and compliance brain**.

---

## 4️⃣ How They Work Together (Recommended Flow)

```text
Developer PR
   ↓
Terraform Code (multi-cloud-secure-tf)
   ↓
Policy Enforcement (sec-iac)
   ↓
CI/CD Validation (Checkov + OPA)
   ↓
Approved Secure AI Infrastructure
```


## 📜 License

This project is licensed under the **MIT License**.

---

## 🤝 Contributing

Contributions are welcome—especially new AI governance policies, security controls, and cloud integrations. Please submit pull requests with clear descriptions and supporting rationale.

---

**sec-iac** helps teams move fast with AI—*without compromising security or compliance.*
