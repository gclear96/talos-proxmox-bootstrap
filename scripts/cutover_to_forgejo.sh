#!/usr/bin/env bash
set -euo pipefail

# Placeholder helper: you will still need to create the repo/org in Forgejo and push/mirror.
#
# Suggested approach:
# 1) In your platform repo locally:
#    git remote add forgejo https://<forgejo>/YOURORG/talos-platform.git
#    git push --mirror forgejo
#
# 2) Update the bootstrap repo's platform_repo_url to the Forgejo URL and re-run:
#    terraform apply

echo "See comments in this script for the recommended cutover steps."
