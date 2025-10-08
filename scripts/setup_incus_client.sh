#!/bin/bash

set -ou pipefail

if ! incus >/dev/null 2>&1; then
    brew install incus
    if [[ $? -ne 0 ]]; then
        echo "failed to install incus"
        exit 1
    fi
fi

rm -rf ~/.config/incus && rm -rf ~/.config/incus.bak

mv ~/.config/incus ~/.config/incus.bak


remote_address=$1
remote_name=$2
incus remote add $remote_name $remote_address --accept-certificate
if [[ $? -ne 0 ]]; then
    echo "failed to add remote"
    exit 1
fi

incus remote switch $remote_name
if [[ $? -ne 0 ]]; then
    echo "failed to switch remote"
    exit 1
fi

incus launch images:ubuntu/22.04 $remote_name:my-first-container-1
if [[ $? -ne 0 ]]; then
    echo "failed to launch container"
    exit 1
fi



exit 0