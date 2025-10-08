#!/bin/bash

set -ou pipefail

function add_new_project() {
    project_name=$1
    storage_name="storage-base-$project_name"

    incus storage create $storage_name dir
    if [[ $? -ne 0 ]]; then
        echo "failed to create storage"
        return 1
    fi

    isolate_feature_in_project=true
    incus project create $project_name --config restricted=true \
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

    # copy the contents of the default project’s default profile into the current project’s default profile
    incus profile show default --project default | incus profile edit default
    if [[ $? -ne 0 ]]; then
        echo "failed to copy profile"
        return 1
    fi

    incus project set $project_name limits.containers=5
    if [[ $? -ne 0 ]]; then
        echo "failed to set limits"
        return 1
    fi
    
    incus profile device add default root-${project_name} disk path=/ pool=$storage_name
    if [[ $? -ne 0 ]]; then
        echo "failed to add profile device"
        return 1
    fi

    #incus project set $project_name limits.cpu=2
    #incus project set $project_name limits.memory=2GB

    incus project switch $project_name
    if [[ $? -ne 0 ]]; then
        echo "failed to add profile device"
        return 1
    fi

    incus profile device add default "root-${project_name}" disk path=/ pool=$storage_name
    if [[ $? -ne 0 ]]; then

        echo "failed to add profile device"
        return 1
    fi
}

project_name=$1
identity="${project_name}-root"

cleanup() {
    incus project switch default
    if [[ $? -ne 0 ]]; then
        echo "failed to switch to default project"
        exit 1
    fi
}

trap cleanup EXIT

incus project switch default
if [[ $? -ne 0 ]]; then
    echo "failed to switch to default project"
    exit 1
fi

add_new_project $project_name
if [[ $? -ne 0 ]]; then
    exit 1
fi

incus config trust add $identity --projects $project_name --restricted
if [[ $? -ne 0 ]]; then
    echo "failed to add identity"
    exit 1
fi

exit 0