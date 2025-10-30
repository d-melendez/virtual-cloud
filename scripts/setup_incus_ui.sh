#!/bin/bash

set -ou pipefail

cd /

if [[ -d virtual-cloud-ui ]]; then
    rm -rf virtual-cloud-ui
fi

git clone https://github.com/d-melendez/virtual-cloud-ui.git
if [[ $? -ne 0 ]]; then
    echo "failed to clone virtual-cloud-ui"
    exit 1
fi

cd virtual-cloud-ui

sudo npm install -g yarn
if [[ $? -ne 0 ]]; then
    echo "failed to install yarn"
    exit 1
fi

yarn install && yarn build
if [[ $? -ne 0 ]]; then
    echo "failed to build virtual-cloud-ui"
    exit 1
fi

sudo rsync -a --delete build/ui/ /opt/incus/ui/
if [[ $? -ne 0 ]]; then
    echo "failed to setup incus ui"
    exit 1
fi

exit 0