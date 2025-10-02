#!/bin/bash

set -o pipefail


function add_new_project() {
    project_name=$1
    incus project create $project_name --config restricted=true
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    incus project set $project_name restricted.containers.nesting=block
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    incus project set $project_name limits.containers=5
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    incus project set $project_name limits.cpu=2
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    incus project set $project_name limits.memory=2GB
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
}


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

identity="my-mac"
project_name="my-project"


add_new_project $project_name
if [[ $? -ne 0 ]]; then
    exit 1
fi

incus config trust add $identity --projects $project_name --restricted