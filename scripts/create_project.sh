#!/bin/bash

set -ou pipefail

function add_new_project() {
    project_name="$1"
    storage_name="storage-base-$project_name"

    incus storage create "$storage_name" dir
    if [[ $? -ne 0 ]]; then
        echo "failed to create storage"
        return 1
    fi

    isolate_feature_in_project=true
    incus project create "$project_name" --config restricted=true \
        --config restricted.backups=allow \
        --config features.profiles=$isolate_feature_in_project \
        --config features.images=$isolate_feature_in_project \
        --config features.networks=$isolate_feature_in_project \
        --config features.networks.zones=$isolate_feature_in_project \
        --config restricted.devices.disk="managed" \
        --config features.storage.buckets=$isolate_feature_in_project \
        --config features.storage.volumes=$isolate_feature_in_project
    if [[ $? -ne 0 ]]; then
        echo "failed to create project"
        return 1
    fi

    incus profile show default --project default | incus profile edit default --project "$project_name"
    if [[ $? -ne 0 ]]; then
        echo "failed to copy profile"
        return 1
    fi

    incus project set "$project_name" limits.containers=5
    if [[ $? -ne 0 ]]; then
        echo "failed to set limits"
        return 1
    fi

    incus project switch "$project_name"
    if [[ $? -ne 0 ]]; then
        echo "failed to switch to new project"
        return 1
    fi

    incus profile device set default root pool "$storage_name"
    if [[ $? -ne 0 ]]; then
        echo "failed to set device pool"
        return 1
    fi
}

project_name="$1"
identity="${project_name}-root"

if [[ -z "${project_name:-}" ]]; then
    echo "usage: bash $0 <project_name>"
    exit 1
fi

cleanup() {
    incus project switch default
    if [[ $? -ne 0 ]]; then
        echo "failed to switch to default project"
        exit 1
    fi
}

trap cleanup EXIT

# Ensure we start from the global project
incus project switch default
if [[ $? -ne 0 ]]; then
    echo "failed to switch to default project"
    exit 1
fi

add_new_project "$project_name"
if [[ $? -ne 0 ]]; then
    exit 1
fi

# 7) Create a project-restricted trust token/identity
incus config trust add "$identity" --projects "$project_name" --restricted
if [[ $? -ne 0 ]]; then
    echo "failed to add identity"
    exit 1
fi

exit 0
