#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing MicroStack"

# Try a sequence of channels to handle track changes.
# Priority: MICROSTACK_CHANNEL (if set) -> latest/stable -> detected stable tracks -> no channel

try_install() {
  local channel="${1:-}"
  if [[ -n "$channel" ]]; then
    echo "==> Attempting: snap install microstack --classic --channel=$channel"
    if sudo snap install microstack --classic --channel="$channel"; then
      return 0
    fi
  else
    echo "==> Attempting: snap install microstack --classic (no channel)"
    if sudo snap install microstack --classic; then
      return 0
    fi
  fi
  return 1
}

contains() {
  local needle="$1"; shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

declare -a candidates=()

# 1) Env override (e.g., MICROSTACK_CHANNEL=latest/stable)
if [[ -n "${MICROSTACK_CHANNEL:-}" ]]; then
  candidates+=("$MICROSTACK_CHANNEL")
fi

# 2) Prefer latest/stable early
if ! contains "latest/stable" "${candidates[@]:-}"; then
  candidates+=("latest/stable")
fi

# 3) Auto-detect other stable channels from snap info
mapfile -t detected < <(snap info microstack 2>/dev/null | \
  grep -E '^[[:space:]]*(latest|[0-9]{4}\.[0-9])\/stable:' | \
  awk '{print $1}' | sed 's/:$//' | sed 's/^\s\+//') || true

for ch in "${detected[@]:-}"; do
  if [[ -n "$ch" ]] && ! contains "$ch" "${candidates[@]:-}"; then
    candidates+=("$ch")
  fi
done

# 4) Finally, try no channel
candidates+=("")

installed=false
for ch in "${candidates[@]}"; do
  if try_install "$ch"; then
    installed=true
    break
  fi
done

if [[ "$installed" != true ]]; then
  echo "ERROR: Failed to install microstack from available channels." >&2
  echo "Hint: Set MICROSTACK_CHANNEL to a specific track, e.g.:" >&2
  echo "  MICROSTACK_CHANNEL=latest/stable ${BASH_SOURCE[0]}" >&2
  exit 1
fi

echo "==> Initializing MicroStack"
sudo microstack init --auto

echo "==> MicroStack services:"
sudo snap services microstack


