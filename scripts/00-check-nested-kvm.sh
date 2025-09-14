#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking virtualization support"
egrep -c '(vmx|svm)' /proc/cpuinfo || true
lsmod | grep -E 'kvm(_intel|_amd)?' || true

MOD=intel
grep -q vmx /proc/cpuinfo && MOD=intel || MOD=amd

PARAM="/sys/module/kvm_${MOD}/parameters/nested"
if [[ -f "$PARAM" ]]; then
  echo -n "Nested virtualization: "
  cat "$PARAM"
else
  echo "Nested parameter file not found. Provider may not expose KVM properly."
fi


