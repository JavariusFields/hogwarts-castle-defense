# \### Hogwarts Castle Defense — Secure Cloud Architecture \& SIEM Pipeline

This is a production-grade, secure multi-tier cloud infrastructure and centralized security information and event management (SIEM) pipeline built on Google Cloud Platform (GCP) and managed with Terraform.

Architecture Overview

This project implements defense-in-depth principles in a dedicated GCP Virtual Private Cloud (hogwarts-vpc), which isolates compute workloads while maintaining secure administrative access and centralized log auditing.



!\[Hogwarts Castle Defense Architecture](assets/gcp\_architecture.png)



#### \### Security Controls Implemented

**Zero-Trust Administrative Access:** Ingress SSH (port 22) is strictly limited to Google's Identity-Aware Proxy (IAP) CIDR range (35.235.240.0/20), which eliminates public IP exposure.

**Network Isolation:** Workloads are housed in dedicated private subnets with outbound internet access routed exclusively through Cloud NAT.

**Centralized SIEM Pipeline:** For seamless audit tracking, a Log Router sink automatically pipes admin and data-access events directly into a dedicated BigQuery dataset (hogwarts\_siem\_logs). This pipeline is locked down using scoped IAM writer permissions to keep the data secure.

**Immutable Storage Vault:** To prevent logs from being tampered with or deleted, they were stored in a Compliance Cloud Storage bucket and secured with a uniform bucket-level access. It was locked with a 24-hour WORM retention policy.



#### \### Infrastructure as Code (Terraform)

This code is managed using Terraform with remote state separation and lifecycle safeguards for live virtual machine preservation.

