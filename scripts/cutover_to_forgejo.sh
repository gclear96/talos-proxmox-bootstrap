#!/usr/bin/env bash
set -euo pipefail

# Helper: mirror the platform repo and print the Terraform vars you need to update.
#
# Usage:
#   ./scripts/cutover_to_forgejo.sh <gh_url> <forgejo_url>
#
# Example:
#   ./scripts/cutover_to_forgejo.sh \
#     https://github.com/YOUR_GH_USER/talos-platform.git \
#     https://forgejo.example.com/YOURORG/talos-platform.git

GH_URL=${1:?github url}
FORGEJO_URL=${2:?forgejo url}

cat <<EOF
1) In the platform repo:
   ./hack/set-repourl.sh ${GH_URL} ${FORGEJO_URL}
   git commit -am "chore: repourl cutover to forgejo"
   git push
   git push --mirror <forgejo-remote>

2) In this repo (bootstrap), update:
   platform_repo_url = "${FORGEJO_URL}"
   # if private, also set platform_repo_username/platform_repo_password (prefer TF_VAR_platform_repo_password)

3) Re-apply:
   cd terraform && terraform apply
EOF
