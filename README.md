# OpenStack + Terraform on VPS (MicroStack)

This project deploys a single-node OpenStack (MicroStack) on your VPS and uses Terraform to spin up a test VM.

## Steps

```bash
# make scripts executable
chmod +x scripts/*.sh

# 0) Check virtualization support
./scripts/00-check-nested-kvm.sh

# 1) Install MicroStack
./scripts/10-install-microstack.sh

# 2) Bootstrap OpenStack (image, flavor, SG, keypair)
./scripts/20-bootstrap-openstack.sh

# 3) Create Application Credential and clouds.yaml
./scripts/30-create-app-cred-and-clouds-yaml.sh

# 4) Terraform smoke test (creates a VM)
./scripts/40-terraform-smoke.sh
```

Remote Terraform use

Copy ~/.config/openstack/clouds.yaml and tf-app.json to your local computer.

On your local computer, install Terraform and place the copied files under ~/.config/openstack/.

Then run terraform init && terraform apply in the terraform/ folder locally.

Ensure your VPS firewall allows inbound access to port 5000 (Keystone) and other OpenStack API ports.
