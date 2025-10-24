#!/bin/bash

set -ou pipefail

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
if [[ $? -ne 0 ]]; then
    exit 1
fi

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
if [[ $? -ne 0 ]]; then
    exit 1
fi

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
if [[ $? -ne 0 ]]; then
    exit 1
fi

sudo apt-get update && sudo apt-get install terraform
if [[ $? -ne 0 ]]; then
    exit 1
fi

exit 0