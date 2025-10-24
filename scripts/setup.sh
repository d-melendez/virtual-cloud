#!/bin/bash

set -euo pipefail

auth0_domain=$1
client_id=$2
client_secret=$3
incus_ip_address="${4}:8443"


# go to the root of the repository
cd "$(git rev-parse --show-toplevel)"

. ./scripts/setup_terraform.sh
if [[ $? -ne 0 ]]; then
    echo "failed to setup terraform"
    exit 1
fi

bash ./scripts/apply_bootstrap_terraform.sh "$auth0_domain" "$client_id" "$client_secret" "$incus_ip_address"
if [[ $? -ne 0 ]]; then
    echo "failed to apply bootstrap terraform"
    exit 1
fi

. ./scripts/setup_incus_server.sh "$auth0_domain"
if [[ $? -ne 0 ]]; then
    echo "failed to setup server"
    exit 1
fi

exit 0