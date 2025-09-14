#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing MicroStack"
sudo snap install microstack --classic --channel=2023.2/stable

echo "==> Initializing MicroStack"
sudo microstack init --auto

echo "==> MicroStack services:"
sudo snap services microstack


