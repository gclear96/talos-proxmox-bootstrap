# Talos on Proxmox – bootstrap repo

This repo is intended to be run locally. It provisions 3 Talos Linux VMs on Proxmox, bootstraps a Kubernetes cluster, installs Argo CD, and applies a single **root** Argo CD Application that points at the platform repo.

> Notes:
> - This is a **scaffold**: you’ll likely tweak Proxmox VM settings (disks, BIOS/UEFI, storage IDs, ISO attachment).
> - Credentials are expected via env vars (recommended) or `terraform.tfvars`.

## Prereqs

- Terraform (or OpenTofu) 1.5+
- Proxmox VE API endpoint + token with VM/storage permissions
- A Talos ISO URL you can download into Proxmox *or* a Talos ISO already present on Proxmox storage
- A Talos installer image tag for `talos_installer_image` (example: `ghcr.io/siderolabs/installer:v1.8.0`)
- `talosctl` and `kubectl` are helpful for debugging (not required for the Terraform plan itself)
- Each Proxmox node must have hardware virtualization enabled (Intel VT-x / AMD-V). If one node lacks it, VMs on that node will fail to start with “KVM virtualization configured, but not available”.

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

## Smoke tests

```bash
KUBECONFIG=../out/homelab.kubeconfig kubectl get nodes -o wide
KUBECONFIG=../out/homelab.kubeconfig kubectl get pods -A
KUBECONFIG=../out/homelab.kubeconfig kubectl -n argocd get pods
KUBECONFIG=../out/homelab.kubeconfig kubectl -n argocd get applications,applicationsets,appprojects
```

To access Argo CD UI quickly:

```bash
KUBECONFIG=../out/homelab.kubeconfig kubectl -n argocd port-forward svc/argo-cd-argocd-server 8080:443
KUBECONFIG=../out/homelab.kubeconfig kubectl -n argocd get secret argo-cd-argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
```

## Proxmox VM defaults (Talos-friendly)

The VM resource is configured for Talos-on-Proxmox guidance:
- UEFI/OVMF + `q35`
- CPU type `host`
- VirtIO NIC model
- VirtIO SCSI controller (`virtio-scsi-pci`, not `virtio-scsi-single`)
- memory ballooning disabled (`floating = 0`)

## Talos ISO handling

You must provide *either*:
- `talos_iso_url` (Terraform downloads the ISO into Proxmox), or
- `talos_iso_file_id` (reference an ISO you already uploaded to Proxmox, e.g. `local:iso/talos.iso`)

If `iso_datastore_id` is not shared across Proxmox nodes, the ISO will be downloaded once per unique `node_name`
in `var.nodes`.

## Talos install + VIP

- `talos_installer_image` is required (example: `ghcr.io/siderolabs/installer:v1.8.0`).
- For a stable API endpoint, set `cluster_vip_ip` (and keep `cluster_endpoint` pointing at the same IP).

## Root app / cutover to Forgejo

1) Start with GitHub as `platform_repo_url`.
2) Once Forgejo is deployed by Argo CD, mirror/push the platform repo to Forgejo.
3) Update `platform_repo_url` to your Forgejo URL and re-run:

```bash
terraform apply
```

See `scripts/` for helper commands.

If your platform repo is private (common after cutover to in-cluster Forgejo), set `platform_repo_username` and
`platform_repo_password` (prefer `TF_VAR_platform_repo_password` env var) so Argo CD can fetch it.

See `CUTOVER.md` for the end-to-end procedure.

## Troubleshooting: “KVM virtualization configured, but not available”

If a VM fails to start on a specific Proxmox node with:

> KVM virtualisation configured, but not available. Either disable in VM configuration or enable in BIOS.

Fix it on that Proxmox node (example checks):

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
lsmod | grep -E '^kvm|kvm_intel|kvm_amd' || true
```

If `/proc/cpuinfo` has no `vmx` (Intel) or `svm` (AMD) flags, enable virtualization in that machine’s BIOS/UEFI and reboot the node.
