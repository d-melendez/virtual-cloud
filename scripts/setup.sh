#!/bin/bash

set -euo pipefail

# go to the root of the repository
cd "$(git rev-parse --show-toplevel)"

# Load environment from .env (do not echo secrets)
if [[ ! -f scripts/vars.env ]]; then
    echo "vars.env file not found at repo root"
    exit 1
fi

set -a
. ./scripts/vars.env
set +a

# Validate required variables
if [[ -z "${AUTH0_DOMAIN:-}" || -z "${AUTH0_CLIENT_ID:-}" || -z "${AUTH0_CLIENT_SECRET:-}" || -z "${INCUS_IP:-}" ]]; then
    echo "missing one or more required variables in .env: AUTH0_DOMAIN, AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET, INCUS_IP"
    exit 1
fi

# Map to local variables and normalize values
auth0_domain="${AUTH0_DOMAIN}"
auth0_client_id="${AUTH0_CLIENT_ID}"
auth0_client_secret="${AUTH0_CLIENT_SECRET}"
incus_ip_address="${INCUS_IP}:8443"

bash scripts/setup_terraform.sh
if [[ $? -ne 0 ]]; then
    echo "failed to setup terraform"
    exit 1
fi

bash scripts/apply_bootstrap_terraform.sh "$auth0_domain" "$auth0_client_id" "$auth0_client_secret" "$incus_ip_address"
if [[ $? -ne 0 ]]; then
    echo "failed to apply bootstrap terraform"
    exit 1
fi

bash scripts/setup_incus_server.sh "$auth0_domain"
if [[ $? -ne 0 ]]; then
    echo "failed to setup server"
    exit 1
fi

exit 0