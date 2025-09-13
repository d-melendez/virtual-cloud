#!/usr/bin/env bash
set -euo pipefail

# Configure Horizon's local_settings.py using env vars
LOCAL_SETTINGS="/etc/openstack-dashboard/local_settings.py"

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

# Replace simple settings in local_settings.py safely
replace_or_append() {
  local key="$1"; shift
  local value="$1"; shift
  local pattern="^${key} ="
  if grep -qE "$pattern" "$LOCAL_SETTINGS"; then
    sed -i "s#${pattern}.*#${key} = ${value}#" "$LOCAL_SETTINGS"
  else
    printf "\n${key} = ${value}\n" >> "$LOCAL_SETTINGS"
  fi
}

bool_py() {
  case "${1:-false}" in
    true|True|1|yes|on) echo True ;;
    *) echo False ;;
  esac
}

# Apply env-configurable settings
TIME_ZONE=${HORIZON_TIME_ZONE:-UTC}
ALLOWED=${HORIZON_ALLOWED_HOSTS:-*}
DEBUG_BOOL=$(bool_py "${HORIZON_DEBUG:-false}")
WEBROOT_VAL=${HORIZON_WEBROOT:-/}
KEYSTONE_URL=${HORIZON_KEYSTONE_URL:-}

replace_or_append "DEBUG" "$DEBUG_BOOL"
replace_or_append "ALLOWED_HOSTS" "['${ALLOWED}']"
replace_or_append "TIME_ZONE" "'${TIME_ZONE}'"
replace_or_append "WEBROOT" "'${WEBROOT_VAL}'"

if [ -n "$KEYSTONE_URL" ]; then
  replace_or_append "OPENSTACK_KEYSTONE_URL" "'${KEYSTONE_URL}'"
fi

# Use in-process cache to avoid external memcached dependency in container
replace_or_append "CACHES" "{ 'BACKEND': 'django.core.cache.backends.locmem.LocMemCache' }"

# Ensure Apache runs in foreground
exec "$@"


