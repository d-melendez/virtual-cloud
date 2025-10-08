#!/bin/bash

set -ou pipefail

remote_address="$1"
remote_name="$2"
token="$3"

bash ./scripts/setup_incus_server.sh "$remote_name"
if [[ $? -ne 0 ]]; then
    echo "failed to setup server"
    exit 1
fi

incus remote add $remote_name "${remote_address}:8443"
if [[ $? -ne 0 ]]; then
    echo "failed to add root remote"
    exit 1
fi

incus remote switch $remote_name
if [[ $? -ne 0 ]]; then
    echo "failed to switch to root remote"
    exit 1
fi

incus config trust add-certificate ~/Downloads/incus-ui.crt --token "$token"
if [[ $? -ne 0 ]]; then
    echo "failed to add certificate"
    exit 1
fi

exit 0