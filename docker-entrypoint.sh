#!/usr/bin/env bash
set -euo pipefail

# Configure Horizon using an overrides file in local_settings.d (no envs)
LOCAL_SETTINGS="/etc/openstack-dashboard/local_settings.py"
OVERRIDES_DIR="/etc/openstack-dashboard/local_settings.d"
OVERRIDES_FILE="${OVERRIDES_DIR}/99-defaults.py"

# Always write a minimal, deterministic base config to avoid memcached dependency
cat > "$LOCAL_SETTINGS" <<'PY'
from django.utils.translation import gettext_lazy as _

DEBUG = False
ALLOWED_HOSTS = ['*']
TIME_ZONE = 'UTC'
WEBROOT = '/horizon/'

# Set Keystone endpoint if needed
# OPENSTACK_KEYSTONE_URL = 'http://keystone:5000/v3'

# Use in-process cache to avoid external memcached dependency
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}
PY

# Helpers
bool_py() {
  case "${1:-false}" in
    true|True|1|yes|on) echo True ;;
    *) echo False ;;
  esac
}

mkdir -p "$OVERRIDES_DIR"
cat > "$OVERRIDES_FILE" <<'PY'
# Auto-generated defaults by docker-entrypoint.sh
DEBUG = False
ALLOWED_HOSTS = ['*']
TIME_ZONE = 'UTC'
WEBROOT = '/horizon/'
# Set your Keystone endpoint here if needed
# OPENSTACK_KEYSTONE_URL = 'http://keystone:5000/v3'

# Use in-process cache to avoid external memcached dependency in container
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}
PY

# Ensure Apache runs in foreground
exec "$@"


