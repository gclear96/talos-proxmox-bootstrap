#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${script_dir}/load-garage-env.sh"

terraform -chdir=terraform init -input=false \
  -backend-config="endpoint=${TF_S3_ENDPOINT}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="force_path_style=true" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_region_validation=true"
