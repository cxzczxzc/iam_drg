variable "project_id" {
  description = "The GCP project id the terraform will be run in the context of"
  type        = string
}

variable "direct_role_grants" {
  description = "The list of roles to be granted to the project level IaC service account directly"
  type        = list(string)
  default     = []
}


variable "delegated_role_grants" {
  description = "The list of roles the the project level IaC service account will be able to grant to other principals within the given project"
  type        = list(string)
  default     = []
}

variable "terraform_service_account_for_project" {
  description = "Name of the service account used at the project level for IaC. This must begin with the prefix serviceAccount:"
  type        = string
}
