#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Bootstrap Forgejo repos (create + mirror push) for the homelab cluster cutover.

This script:
  - waits for Forgejo API to be reachable
  - creates repos in Forgejo (if missing)
  - mirrors local repos into Forgejo via `git push --mirror`

It does NOT:
  - update Argo CD repoURLs (use the existing CUTOVER docs/scripts)
  - deploy/enable Forgejo runner
  - configure CI secrets (Vault/CA/JWT/state backend)

Usage:
  ./scripts/bootstrap_forgejo_repos.sh \
    --forgejo-url https://forgejo.k8s.magomago.moe \
    --owner gclear96 \
    --owner-type user \
    --username <forgejo-username> \
    --token-file ../out/forgejo.token \
    [--overwrite-existing]

Required inputs:
  --forgejo-url           Base URL (scheme + host), e.g. https://forgejo.example.com
  --owner                 Forgejo owner (org or user) that will own the repos
  --owner-type            "org" or "user"
  --username              Forgejo username (used for git HTTP basic auth)
  --token-file            Path to Forgejo PAT file (single line), OR set FORGEJO_TOKEN env var

Flags:
  --overwrite-existing    If the Forgejo repo already exists, allow overwriting refs via --mirror.

Repos mirrored by default (workspace layout):
  - talos-proxmox-bootstrap-repo -> <owner>/talos-proxmox-bootstrap.git
  - talos-proxmox-platform-repo  -> <owner>/talos-proxmox-platform.git
  - vault-terraform-repo         -> <owner>/vault-terraform-repo.git
  - authentik-terraform-repo     -> <owner>/authentik-terraform-repo.git

EOF
}

FORGEJO_URL=""
FORGEJO_OWNER=""
FORGEJO_OWNER_TYPE=""
FORGEJO_USERNAME=""
FORGEJO_TOKEN_FILE=""
OVERWRITE_EXISTING="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --forgejo-url)
      FORGEJO_URL="${2:?missing value}"; shift 2;;
    --owner)
      FORGEJO_OWNER="${2:?missing value}"; shift 2;;
    --owner-type)
      FORGEJO_OWNER_TYPE="${2:?missing value}"; shift 2;;
    --username)
      FORGEJO_USERNAME="${2:?missing value}"; shift 2;;
    --token-file)
      FORGEJO_TOKEN_FILE="${2:?missing value}"; shift 2;;
    --overwrite-existing)
      OVERWRITE_EXISTING="true"; shift 1;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${FORGEJO_URL}" || -z "${FORGEJO_OWNER}" || -z "${FORGEJO_OWNER_TYPE}" || -z "${FORGEJO_USERNAME}" ]]; then
  echo "Missing required args." >&2
  usage
  exit 2
fi

if [[ "${FORGEJO_OWNER_TYPE}" != "org" && "${FORGEJO_OWNER_TYPE}" != "user" ]]; then
  echo "--owner-type must be 'org' or 'user'." >&2
  exit 2
fi

FORGEJO_URL="${FORGEJO_URL%/}"
API_BASE="${FORGEJO_URL}/api/v1"

FORGEJO_TOKEN="${FORGEJO_TOKEN:-}"
if [[ -z "${FORGEJO_TOKEN}" ]]; then
  if [[ -z "${FORGEJO_TOKEN_FILE}" || ! -f "${FORGEJO_TOKEN_FILE}" ]]; then
    echo "Set FORGEJO_TOKEN or provide --token-file pointing to a file containing the token." >&2
    exit 2
  fi
  FORGEJO_TOKEN="$(tr -d '\r\n' < "${FORGEJO_TOKEN_FILE}")"
fi

if [[ -z "${FORGEJO_TOKEN}" ]]; then
  echo "Forgejo token is empty." >&2
  exit 2
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 2; }
}

require_cmd curl
require_cmd jq
require_cmd git
require_cmd base64

echo "Waiting for Forgejo API at ${API_BASE}/version ..."
for i in $(seq 1 120); do
  if curl -fsS "${API_BASE}/version" >/dev/null 2>&1; then
    break
  fi
  sleep 2
  if [[ "${i}" -eq 120 ]]; then
    echo "Timed out waiting for Forgejo API. Check ingress/DNS for ${FORGEJO_URL}." >&2
    exit 1
  fi
done

echo "Forgejo version:"
curl -fsS "${API_BASE}/version" | jq .

AUTH_HEADER="Authorization: token ${FORGEJO_TOKEN}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd -- "${script_dir}/../.." && pwd)"

mirror_one() {
  local local_path="$1"
  local forgejo_repo_name="$2"

  if [[ ! -d "${local_path}" ]]; then
    echo "Missing local repo dir: ${local_path}" >&2
    return 1
  fi

  if ! git -C "${local_path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not a git repo: ${local_path}" >&2
    return 1
  fi

  echo
  echo "== ${forgejo_repo_name} =="

  if curl -fsS -H "${AUTH_HEADER}" "${API_BASE}/repos/${FORGEJO_OWNER}/${forgejo_repo_name}" >/dev/null 2>&1; then
    echo "Forgejo repo exists: ${FORGEJO_OWNER}/${forgejo_repo_name}"
    if [[ "${OVERWRITE_EXISTING}" != "true" ]]; then
      echo "Skipping mirror push (repo exists). Re-run with --overwrite-existing to force --mirror." >&2
      return 0
    fi
  else
    echo "Creating Forgejo repo: ${FORGEJO_OWNER}/${forgejo_repo_name}"
    if [[ "${FORGEJO_OWNER_TYPE}" == "org" ]]; then
      curl -fsS -X POST -H "${AUTH_HEADER}" -H "Content-Type: application/json" \
        -d "$(jq -n --arg name "${forgejo_repo_name}" '{name:$name, private:true}')" \
        "${API_BASE}/orgs/${FORGEJO_OWNER}/repos" >/dev/null
    else
      curl -fsS -X POST -H "${AUTH_HEADER}" -H "Content-Type: application/json" \
        -d "$(jq -n --arg name "${forgejo_repo_name}" '{name:$name, private:true}')" \
        "${API_BASE}/user/repos" >/dev/null
    fi
  fi

  local git_url="${FORGEJO_URL}/${FORGEJO_OWNER}/${forgejo_repo_name}.git"
  local basic
  basic="$(printf '%s:%s' "${FORGEJO_USERNAME}" "${FORGEJO_TOKEN}" | base64 | tr -d '\n')"

  echo "Mirroring local -> Forgejo:"
  echo "  local:  ${local_path}"
  echo "  remote: ${git_url}"

  GIT_TERMINAL_PROMPT=0 \
    git -C "${local_path}" -c "http.extraHeader=Authorization: Basic ${basic}" \
    push --mirror "${git_url}"
}

mirror_one "${workspace_root}/talos-proxmox-bootstrap-repo" "talos-proxmox-bootstrap"
mirror_one "${workspace_root}/talos-proxmox-platform-repo" "talos-proxmox-platform"
mirror_one "${workspace_root}/vault-terraform-repo" "vault-terraform-repo"
mirror_one "${workspace_root}/authentik-terraform-repo" "authentik-terraform-repo"

cat <<EOF

Next (cutover):
  - Platform repo URL rewrite + mirror:
      (in talos-proxmox-platform-repo) ./hack/set-repourl.sh <github-url> ${FORGEJO_URL}/${FORGEJO_OWNER}/talos-proxmox-platform.git
      Then follow: talos-proxmox-platform-repo/CUTOVER.md
  - Point the bootstrap root app at Forgejo:
      Follow: talos-proxmox-bootstrap-repo/CUTOVER.md (platform_repo_url -> Forgejo)

Next (Terraform repos CI):
  - Mirror includes .forgejo workflows already; after runner is enabled, set Forgejo repo secrets:
      - talos-proxmox-bootstrap-repo/README.md
      - vault-terraform-repo/README.md
      - authentik-terraform-repo/README.md

EOF
