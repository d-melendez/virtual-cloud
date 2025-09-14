#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing MicroStack"

sudo apt update -y \
    && sudo apt install -y snapd python3 python3-dev \
    && sudo apt clean && sudo apt autoremove -y
if [ $? -ne 0 ]; then
    exit 1
fi

sudo snap install microstack --devmode --beta
if [ $? -ne 0 ]; then
    exit 1
fi

sudo microstack init --auto --control
if [ $? -ne 0 ]; then
    exit 1
fi

exit 0
