#!/usr/bin/env bash
set -euo pipefail

alias OSC="microstack.openstack"

echo "==> Add CirrOS image"
if ! OSC image list -f value -c Name | grep -q '^cirros$'; then
  wget -q -O /tmp/cirros.qcow2 https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img
  OSC image create cirros --disk-format qcow2 --container-format bare --public --file /tmp/cirros.qcow2
fi

echo "==> Ensure m1.small flavor"
if ! OSC flavor list -f value -c Name | grep -q '^m1.small$'; then
  OSC flavor create m1.small --ram 2048 --disk 10 --vcpus 1
fi

echo "==> Allow ICMP + SSH"
PROJECT_ID=$(OSC project show admin -f value -c id)
SG_ID=$(OSC security group list --project "$PROJECT_ID" -f value -c ID | head -n1)
OSC security group rule create --proto icmp "$SG_ID" || true
OSC security group rule create --proto tcp --dst-port 22 "$SG_ID" || true

echo "==> Keypair tf-key"
if [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
  OSC keypair create tf-key --public-key "$HOME/.ssh/id_rsa.pub" || true
else
  echo "No ~/.ssh/id_rsa.pub found. Create one with ssh-keygen."
fi


