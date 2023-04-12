module "gcp_delegated_role_grant" {
  source = "../.."
  project_id                            = var.project_id
  terraform_service_account_for_project = var.terraform_service_account_for_project
  direct_role_grants                    = var.direct_role_grants
  delegated_role_grants                 = var.delegated_role_grants
}

