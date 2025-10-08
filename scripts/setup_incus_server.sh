#!/bin/bash

set -ou pipefail

function setup_zabbly_upstream() {
    SUITE=noble

    sudo install -d -m 0755 /etc/apt/keyrings
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    curl -fsSL https://pkgs.zabbly.com/key.asc | sudo tee /etc/apt/keyrings/zabbly.asc >/dev/null
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Replace any previous broken entry and add the correct one
    sudo rm -f /etc/apt/sources.list.d/zabbly-incus-stable.sources

cat <<EOF | sudo tee /etc/apt/sources.list.d/zabbly-incus-stable.sources >/dev/null
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: ${SUITE}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    return 0
}

setup_zabbly_upstream
if [[ $? -ne 0 ]]; then
    exit 1
fi

sudo apt update &&
    sudo apt install -y incus incus-ui-canonical
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

incus storage create default dir
if [[ $? -ne 0 ]]; then
    exit 1
fi

# Make sure the default profile has a root disk that uses that pool
# (remove any wrong one first, ignore errors if it doesn't exist)
incus profile device remove default root 2>/dev/null || true

incus profile device add default root disk path=/ pool=default
if [[ $? -ne 0 ]]; then
    exit 1
fi


incus config trust add root
if [[ $? -ne 0 ]]; then
    echo "failed to add root identity"
    exit 1
fi

incus config set oidc.issuer=https://dev-mpsujybme3f2dsf6.us.auth0.com/
if [[ $? -ne 0 ]]; then
    echo "failed to set oidc issuer"
    exit 1
fi

incus config set oidc.client.id=nGD0VJr5ZlnRAAf92ngQB9oj9k2Nk714
if [[ $? -ne 0 ]]; then
    echo "failed to set oidc client id"
    exit 1
fi

incus config set oidc.audience=https://dev-mpsujybme3f2dsf6.us.auth0.com/api/v2/
if [[ $? -ne 0 ]]; then
    echo "failed to set oidc audience"
    exit 1
fi


exit 0