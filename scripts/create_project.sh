#!/bin/bash

set -ou pipefail

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

project_name=$1
identity="$project_name-root"

add_new_project $project_name
if [[ $? -ne 0 ]]; then
    exit 1
fi

incus config trust add $identity --projects $project_name --restricted
if [[ $? -ne 0 ]]; then
    exit 1
fi

exit 0