#!/usr/bin/env bash
set -euo pipefail

# Load Garage S3 backend env vars for Terraform.
#
# Notes:
# - This script is safe to *source* or to run as a subprocess.
# - It does not print secrets.

ENV_FILE="${ENV_FILE:-out/garage-tfstate.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Create it first (see vault-terraform-repo/scripts/bootstrap-garage-tfstate.sh)." >&2
  return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

: "${TF_S3_ENDPOINT:?Missing TF_S3_ENDPOINT in ${ENV_FILE}}"
: "${AWS_ACCESS_KEY_ID:?Missing AWS_ACCESS_KEY_ID in ${ENV_FILE}}"
: "${AWS_SECRET_ACCESS_KEY:?Missing AWS_SECRET_ACCESS_KEY in ${ENV_FILE}}"

# Garage advertises region "garage" and expects SigV4 requests to use it.
AWS_REGION="garage"

export TF_S3_ENDPOINT AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION

