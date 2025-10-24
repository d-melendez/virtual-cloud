#!/bin/bash

set -ou pipefail

auth0_domain=$1
client_id=$2
client_secret=$3
incus_ip_address=$4

cd "$(git rev-parse --show-toplevel)"
cd terraform/root

terraform init
if [[ $? -ne 0 ]]; then
    echo "failed to initialize terraform"
    exit 1
fi

terraform apply -auto-approve -var "auth0_domain=$auth0_domain" -var "auth0_client_id=$auth0_client_id" -var "auth0_client_secret=$auth0_client_secret"

. ./scripts/setup_terraform.sh
if [[ $? -ne 0 ]]; then
    echo "failed to setup terraform"
    exit 1
fi

terraform apply -auto-approve