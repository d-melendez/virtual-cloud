#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing MicroStack"

sudo apt update -y \
    && sudo apt install snapd python python-dev -y \
    && sudo apt clean && sudo apt autoremove -y
if [ $? -ne 0 ]; then
    exit 1
fi

sudo snap install microstack --beta
if [ $? -ne 0 ]; then
    exit 1
fi

sudo 
if [ $? -ne 0 ]; then
    exit 1
fi

sudo microstack init --auto --control
if [ $? -ne 0 ]; then
    exit 1
fi

exit 0
