#!/bin/bash

set -ou pipefail

if ! incus >/dev/null 2>&1; then
    brew install incus
    if [[ $? -ne 0 ]]; then
        echo "failed to install incus"
        exit 1
    fi
fi

remote_address="157.245.239.13:8443"
remote_name="my-remote-test"
incus remote add $remote_name $remote_address --accept-certificate
if [[ $? -ne 0 ]]; then
    echo "failed to add remote"
    exit 1
fi

incus launch images:ubuntu/22.04 $remote_name:my-first-container
if [[ $? -ne 0 ]]; then
    echo "failed to launch container"
    exit 1
fi
