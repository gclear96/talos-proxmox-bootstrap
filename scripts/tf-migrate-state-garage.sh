#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${script_dir}/load-garage-env.sh"

MODE="${MODE:-migrate}" # migrate|reconfigure

init_args=("-input=false")
case "${MODE}" in
  migrate)
    init_args+=("-migrate-state")
    # Avoid interactive approval prompt for state migration.
    init_args+=("-force-copy")
    ;;
  reconfigure)
    init_args+=("-reconfigure")
    ;;
  *)
    echo "MODE must be 'migrate' or 'reconfigure' (got: ${MODE})" >&2
    exit 2
    ;;
esac

terraform -chdir=terraform init "${init_args[@]}" \
  -backend-config="endpoint=${TF_S3_ENDPOINT}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="force_path_style=true" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_region_validation=true"
