#!/bin/bash
# =============================================================================
# Quick setup script - Initialize the DevOps Platform
# =============================================================================

echo "========================================="
echo "  DevOps Platform - Setup Script"
echo "========================================="

# Check prerequisites
echo "[1/4] Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "[ERROR] Terraform not found. Install from https://terraform.io"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "[ERROR] Docker not found. Install from https://docker.com"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "[ERROR] kubectl not found."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "[ERROR] AWS CLI not found."; exit 1; }
echo "[OK] All prerequisites found"

# Initialize Terraform
echo "[2/4] Initializing Terraform..."
cd terraform
terraform init
echo "[OK] Terraform initialized"

# Validate Terraform
echo "[3/4] Validating Terraform configs..."
terraform validate
echo "[OK] Terraform configs valid"

# Test Docker builds
echo "[4/4] Testing Docker builds..."
cd ../docker
docker build -t test-python-api ./python-api
docker build -t test-node-frontend ./node-frontend
echo "[OK] Docker images built successfully"

echo ""
echo "========================================="
echo "  Setup complete!"
echo "  Next steps:"
echo "    1. cd terraform && terraform plan"
echo "    2. terraform apply"
echo "    3. Update ansible/inventory/hosts"
echo "========================================="
