#!/usr/bin/env bash
set -euo pipefail

# make scripts executable
chmod +x scripts/*.sh

# 0) Check virtualization support
. ./scripts/00-check-nested-kvm.sh

# 1) Install MicroStack
. ./scripts/10-install-microstack.sh

# 2) Bootstrap OpenStack (image, flavor, SG, keypair)
. ./scripts/20-bootstrap-openstack.sh

# 3) Create Application Credential and clouds.yaml
. ./scripts/30-create-app-cred-and-clouds-yaml.sh

# 4) Terraform smoke test (creates a VM)
. ./scripts/40-terraform-smoke.sh