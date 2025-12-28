# Cutover: GitHub -> in-cluster Forgejo (Argo CD stays healthy)

Goal: move Argo CD from syncing the platform repo on GitHub to syncing the mirrored platform repo on Forgejo, without breaking GitOps.

## Preconditions

- Cluster is bootstrapped and Argo CD is running (`terraform apply` in this repo).
- Forgejo is deployed by Argo CD from the platform repo and is reachable (ingress/NodePort).
- You have created an org/user and an empty repo in Forgejo for the platform repo mirror.

## Steps

1) Mirror/push the platform repo into Forgejo

From your local clone of the platform repo:

```bash
git remote add forgejo https://FORGEJO_HOST/YOURORG/talos-platform.git
git push --mirror forgejo
```

1b) Mirror/push additional repos into Forgejo (optional, recommended)

If you plan to run day-2 Terraform from in-cluster Forgejo (runner/Actions), mirror those repos too:

- Bootstrap repo (`talos-proxmox-bootstrap-repo`)
- Vault Terraform repo (`vault-terraform-repo`)
- Authentik Terraform repo (`authentik-terraform-repo`)

You can use `./scripts/bootstrap_forgejo_repos.sh` to create + mirror both the platform repo and `vault-terraform-repo` once Forgejo is reachable.
That script also supports `authentik-terraform-repo`.

2) Update the platform repo manifests to reference Forgejo

In the platform repo, run:

```bash
./hack/set-repourl.sh https://github.com/YOUR_GH_USER/talos-platform.git https://FORGEJO_HOST/YOURORG/talos-platform.git
git status
git commit -am "chore: repourl cutover to forgejo"
git push
git push --mirror forgejo
```

3) Point the bootstrap root app at Forgejo

Update your `terraform/terraform.tfvars` (or env vars) in this repo:

- `platform_repo_url` -> `https://FORGEJO_HOST/YOURORG/talos-platform.git`
- If the Forgejo repo is private, set:
  - `platform_repo_username`
  - `platform_repo_password` (prefer `TF_VAR_platform_repo_password`)

Then apply:

```bash
cd terraform
terraform apply
```

## Verification

- Argo CD shows the root app syncing from Forgejo:
  - `kubectl --kubeconfig ../out/<cluster>.kubeconfig -n argocd get application platform-root -o yaml | grep -n \"repoURL\" -n`
- Child Applications continue to sync and become Healthy:
  - `kubectl --kubeconfig ../out/<cluster>.kubeconfig -n argocd get applications`
