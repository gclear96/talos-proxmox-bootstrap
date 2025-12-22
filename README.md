# Talos on Proxmox – bootstrap repo

![system diagram](https://github.com/gclear96/talos-proxmox-bootstrap/blob/7569d75400df082f0066cbdbac4450ffbfea9e4c/assets/talos-proxmox.png)

This repo is intended to be run locally. It provisions 3 Talos Linux VMs on Proxmox, bootstraps a Kubernetes cluster, installs Argo CD, and applies a single **root** Argo CD Application that points at the platform repo.

> Notes:
> - This is a **scaffold**: you’ll likely tweak Proxmox VM settings (disks, BIOS/UEFI, storage IDs, ISO attachment).
> - Credentials are expected via env vars (recommended) or `terraform.tfvars`.

## Prereqs

- Terraform (or OpenTofu) 1.5+
- Proxmox VE API endpoint + token with VM/storage permissions
- A Talos ISO URL you can download into Proxmox *or* a Talos ISO already present on Proxmox storage
- A Talos installer image tag for `talos_installer_image` (use an Image Factory build if you need Longhorn; example: `factory.talos.dev/metal-installer/…:v1.11.6`)
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

## First-bootstrap timing (Argo CD)

Right after Talos bootstraps, the Kubernetes API can take a short while to become reachable.
To avoid Helm/Argo CD racing the API, Terraform waits for `/readyz` before installing Argo CD.

- Adjust `kube_apiserver_wait_timeout_seconds` and `kube_apiserver_wait_interval_seconds` in `terraform.tfvars` if needed.
- This check uses `kubectl` locally, so ensure it is installed on the machine running Terraform.

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

- `talos_installer_image` is required (use an Image Factory installer with iSCSI tools if you plan to run Longhorn; example: `factory.talos.dev/metal-installer/…:v1.11.6`).
- For a stable API endpoint, set `cluster_vip_ip` (and keep `cluster_endpoint` pointing at the same IP).

## MetalLB (L2) note for control-plane nodes

Talos control-plane nodes include the label `node.kubernetes.io/exclude-from-external-load-balancers` by default.
MetalLB L2 respects that label and will not announce VIPs from those nodes.

This repo removes the label via `terraform/patches/remove-exclude-lb-label.yaml` so L2 announcements work on control-plane-only clusters.

## Longhorn prerequisites (Talos)

Longhorn requires iSCSI tooling plus specific kernel modules on the nodes that will run Longhorn.

- Kernel modules are enabled in `terraform/patches/node.yaml`:
  - `nbd`, `iscsi_tcp`, `configfs`
- System extensions must be baked into your Talos installer image. Build a custom Image Factory
  installer that includes `iscsi-tools` and `util-linux-tools`, and set `talos_installer_image` to it.

If you skip the extensions, Longhorn will fail to attach volumes.

## Stable node IPs (recommended)

Proxmox does not “set an IP” inside the VM. Talos will bring up networking and typically use DHCP by default.

Recommended approach (stable from first boot, works great with Terraform):

1) Set a fixed `mac_address` per node in `nodes`.
2) Configure your DHCP server/router to reserve the desired `nodes[*].ip` for each MAC.

Optional alternative (Talos static config):

- Set `node_network_mode = "static"` and configure `node_network_prefix`, `node_network_gateway`, and `node_network_nameservers`.
- Note: Terraform still needs initial reachability to the Talos API to apply config, so DHCP reservations are still the smoothest “day 1” path.

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

## Note: Argo CD root app installation

Argo CD is installed via the `argo/argo-cd` chart. The root `Application` is applied via a **second** Helm release
(`platform-root`) so Argo CD CRDs are present before we attempt to create `argoproj.io/v1alpha1` resources.

## Troubleshooting: “KVM virtualization configured, but not available”

If a VM fails to start on a specific Proxmox node with:

> KVM virtualisation configured, but not available. Either disable in VM configuration or enable in BIOS.

Fix it on that Proxmox node (example checks):

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
lsmod | grep -E '^kvm|kvm_intel|kvm_amd' || true
```

If `/proc/cpuinfo` has no `vmx` (Intel) or `svm` (AMD) flags, enable virtualization in that machine’s BIOS/UEFI and reboot the node.

## Troubleshooting: `talos_machine_configuration_apply` “Still creating…”

`talos_machine_configuration_apply` connects to the Talos API on each node IP (port `50000`) and pushes the machine configuration.
If it sits at “Still creating…” for multiple minutes, it almost always means Terraform cannot reach the Talos API on the IPs you configured.

Quick checks from the machine running Terraform:

```bash
for ip in 192.168.50.201 192.168.50.202 192.168.50.203; do
  echo "== $ip =="
  ping -c1 -W1 "$ip" || true
  timeout 2 bash -lc "</dev/tcp/$ip/50000" && echo "port 50000 open" || echo "port 50000 closed"
done
```

Common causes:
- The VMs did not get the IPs you set in `nodes` (Talos ISO boots with DHCP by default). Fix via DHCP reservations *or* add static network config to the Talos patch.
- VLAN/bridge mismatch (e.g., `vm_vlan_id` not set when you expect tagged VLANs).
- The Talos VM didn’t boot into the ISO (check the Proxmox console for each VM and confirm it shows a Talos maintenance screen + IP).
