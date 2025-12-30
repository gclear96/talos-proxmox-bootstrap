#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${script_dir}/load-garage-env.sh"

exec terraform -chdir=terraform plan -input=false -no-color "$@"

