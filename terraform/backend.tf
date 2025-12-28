terraform {
  # Optional remote state in Garage (S3-compatible).
  #
  # IMPORTANT:
  # - Day-0 bootstrap may run before Garage exists; in that case, use local state:
  #     terraform init -backend=false
  # - After Garage is deployed, migrate local state to Garage:
  #     terraform init -migrate-state -reconfigure \
  #       -backend-config="endpoint=${TF_S3_ENDPOINT}" \
  #       -backend-config="force_path_style=true" \
  #       -backend-config="skip_credentials_validation=true" \
  #       -backend-config="skip_metadata_api_check=true" \
  #       -backend-config="skip_region_validation=true"
  #
  # CI expects remote state so merges can reconcile infra deterministically.
  backend "s3" {
    bucket = "tf-state"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

