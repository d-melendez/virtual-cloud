#!/bin/bash

set -o pipefail

brew install incus
if [[ $? -ne 0 ]]; then
    exit 1
fi

remote_address="157.245.239.13:8443"
remote_name="my-remote"
incus remote add $remote_name $remote_address
if [[ $? -ne 0 ]]; then
    exit 1
fi

incus config trust add $remote_address
if [[ $? -ne 0 ]]; then
    exit 1
fi

incus launch images:ubuntu/22.04 $remote_name:my-first-container
if [[ $? -ne 0 ]]; then
    exit 1
fi

add_new_project "my-project"