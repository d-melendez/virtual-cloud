#!/usr/bin/env bash
set -euo pipefail

if ! command -v terraform >/dev/null; then
  echo "==> Installing Terraform"
  sudo apt-get update -y
  sudo apt-get install -y unzip curl
  VER="1.9.5"
  curl -fsSL -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_amd64.zip
  sudo unzip -o /tmp/terraform.zip -d /usr/local/bin
fi

cd "$(dirname "$0")/../terraform"

terraform init -input=false
terraform apply -auto-approve


