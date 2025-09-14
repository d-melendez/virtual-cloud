#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing MicroStack"

sudo apt update -y && sudo apt install snapd -y && sudo snap install microstack --beta && sudo apt clean
if [ $? -ne 0 ]; then
    return 1
fi

return 0
