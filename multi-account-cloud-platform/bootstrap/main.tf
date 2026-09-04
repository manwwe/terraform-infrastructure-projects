module "terraform_state" {
  source = "../modules/terraform-state"

  bucket_name  = var.bucket_name
  kms_alias    = var.kms_alias
  owner        = var.owner
  project_name = var.project_name
  environment  = "shared"
}
