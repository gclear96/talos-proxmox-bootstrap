# Talos on Proxmox – bootstrap repo

This repo is intended to be run locally. It provisions 3 Talos Linux VMs on Proxmox, bootstraps a Kubernetes cluster, installs Argo CD, and applies a single **root** Argo CD Application that points at the platform repo.

> Notes:
> - This is a **scaffold**: you’ll likely tweak Proxmox VM settings (disks, BIOS/UEFI, storage IDs, ISO attachment).
> - Credentials are expected via env vars (recommended) or `terraform.tfvars`.

## Prereqs

- Terraform (or OpenTofu) 1.5+
- Proxmox VE API endpoint + token with VM/storage permissions
- A Talos ISO URL you can download into Proxmox *or* a Talos ISO already present on Proxmox storage
- `talosctl` and `kubectl` are helpful for debugging (not required for the Terraform plan itself)

## Quick start

```bash
cd terraform

cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your environment details

terraform init
terraform apply
```

Outputs include:
- `kubeconfig_path` (written locally)
- `talosconfig_path` (written locally)

## Root app / cutover to Forgejo

1) Start with GitHub as `platform_repo_url`.
2) Once Forgejo is deployed by Argo CD, mirror/push the platform repo to Forgejo.
3) Update `platform_repo_url` to your Forgejo URL and re-run:

```bash
terraform apply
```

See `scripts/` for helper commands (placeholders).
