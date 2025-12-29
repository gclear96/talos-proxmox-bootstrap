terraform {
  # Optional remote state in Garage (S3-compatible).
  #
  # IMPORTANT:
  # - Day-0 bootstrap may run before Garage exists; in that case, use local state:
  #     terraform init -backend=false
  # - After Garage is deployed, migrate local state to Garage:
  #     (from repo root) ./scripts/tf-migrate-state-garage.sh
  #
  # CI expects remote state so merges can reconcile infra deterministically.
  backend "s3" {
    bucket = "tf-state"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}
