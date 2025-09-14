#!/usr/bin/env bash
set -euo pipefail

alias OSC="microstack.openstack"

echo "==> Create Application Credential"
OSC application credential create tf-app --unrestricted --role admin -f json > "$HOME/tf-app.json"
APP_ID=$(jq -r '.id' "$HOME/tf-app.json")
APP_SECRET=$(jq -r '.secret' "$HOME/tf-app.json")
AUTH_URL=$(OSC endpoint list -f value -c URL | grep '/v3' | head -n1)

CONF_DIR="$HOME/.config/openstack"
mkdir -p "$CONF_DIR"
cat > "$CONF_DIR/clouds.yaml" <<EOF
clouds:
  microstack:
    auth:
      auth_url: "$AUTH_URL"
      application_credential_id: "$APP_ID"
      application_credential_secret: "$APP_SECRET"
    region_name: "RegionOne"
    interface: "public"
    identity_api_version: 3
EOF

echo "==> clouds.yaml written to $CONF_DIR/clouds.yaml"


