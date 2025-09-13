#!/usr/bin/env bash
set -euo pipefail

# Configure Horizon using an overrides file in local_settings.d (no envs)
LOCAL_SETTINGS="/etc/openstack-dashboard/local_settings.py"
OVERRIDES_DIR="/etc/openstack-dashboard/local_settings.d"
OVERRIDES_FILE="${OVERRIDES_DIR}/99-defaults.py"

# Ensure file exists (package provides a default). If missing, create minimal base.
if [ ! -f "$LOCAL_SETTINGS" ]; then
  cat >/etc/openstack-dashboard/local_settings.py <<'PY'
from django.utils.translation import gettext_lazy as _
DEBUG = False
ALLOWED_HOSTS = ['*']
WEBROOT = '/'
OPENSTACK_HOST = '127.0.0.1'
OPENSTACK_KEYSTONE_URL = 'http://%s:5000/v3' % OPENSTACK_HOST
PY
fi

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
WEBROOT = '/'
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


