#!/bin/bash

set -euo pipefail

auth0_domain=$1
auth0_client_id=$2
auth0_client_secret=$3
incus_ip_address=$4

cd "$(git rev-parse --show-toplevel)"
cd terraform/root

terraform init
if [[ $? -ne 0 ]]; then
    echo "failed to initialize terraform"
    exit 1
fi

terraform apply -auto-approve \
  -var "auth0_domain=$auth0_domain" \
  -var "auth0_client_id=$auth0_client_id" \
  -var "auth0_client_secret=$auth0_client_secret" \
  -var "incus_ip_address=$incus_ip_address"
if [[ $? -ne 0 ]]; then
    echo "failed to apply terraform"
    exit 1
fi

exit 0