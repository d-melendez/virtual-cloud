#!/bin/bash

set -o pipefail

sudo apt update && sudo apt install -y incus
if [[ $? -ne 0 ]]; then
    exit 1
fi

if ! incus info >/dev/null 2>&1; then
    sudo incus admin init
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi

incus config set core.https_address :8443
if [[ $? -ne 0 ]]; then
    exit 1
fi

exit 0