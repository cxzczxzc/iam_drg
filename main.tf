# Parsing done to overcome some technical limitation of 
# IAM conditions to make it scalable
# For details see README section Technical Details about the DRG IAM condition
locals {
  roles = formatlist("'%s'", sort(var.delegated_role_grants))
  role_chunks = [
    for chunk in chunklist(local.roles, 10) :
    join(", ", chunk)
  ]
  condition_string = "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])"
  conditions       = formatlist(local.condition_string, local.role_chunks)
  expressions = [
    for chunk in chunklist(local.conditions, 13) :
    join(" || ", chunk)
  ]

  delegated_roles = {
    for index, expression in local.expressions :
    "iam_condition_${index + 1}" => {
      expression = expression
      index      = index + 1
    }
  }
}
# This resource will assign admin roles for an approved list of services
# to the service account at the project level used for IaC
resource "google_project_iam_member" "direct_role_assignments" {
  for_each = toset(var.direct_role_grants)
  project  = var.project_id
  role     = each.value
  member   = var.terraform_service_account_for_project
}

# This resource will assign roles/resourcemanager.projectIAMAdmin
# along with IAM conditions that contain delegated role grants
# this is essentially an allow list of roles that could be granted
# by this principal to other principals
resource "google_project_iam_member" "delegated_role_grants" {
  for_each = local.delegated_roles
  project  = var.project_id
  role     = var.restricted_role_grant 
  member   = var.terraform_service_account_for_project
  condition {
    title       = "iam_drg_condition_${each.value.index}"
    description = "IAM Conditions for Delegated role grants (${each.value.index}/${length(local.expressions)})."
    expression  = each.value.expression
  }
}


