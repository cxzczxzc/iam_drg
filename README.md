# Description 

This solution is designed to achieve the goal of implementing principle of least privilege in an organization. 

This module also takes into account preventing users accessing their projects through the console to perform work. Thus, the viewer group for the project gets assigned a set of roles that ensure that console access is read-only. 

# How it works
This solution uses IAM conditions to restrict users to grant themselves excessive permissions.

The solution was tested in an environment configured with the following preconditions:

 - GCP Project
 - Terraform Cloud Service Account
 - VPC Network with at least 1 subnet
 - APIs enabled based on service selection
* There is a `Terraform Cloud Service Account` which is essentially the project level service account. This account is used for IaC, as well as for granting roles to project level identities, so that they can access their required resources. 
* The list of roles that can be granted, however, is restriced. This restriction is enforced in code using IAM conditions. This service account itself has `roles/resourcemanager.projectIamAdmin` as well as other admin roles for approved services, which can be found in `variables.tf` file.
* Users use the Terraform Cloud Workspace, which is authenticated and authorized to create resources in the GCP Project by the `Terraform Cloud Service Account`.

## Technical Details about the DRG IAM condition

IAM conditions use a CEL (Common Expression Language) expression syntax to build IAM conditions. 

```
api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])
```
The `%s` is replaced by a list of roles (roles that can be granted to other principals, i.e. allow-listed roles). There is a limit of 10 roles allowed per `.hasOnly()` call. Additionally, 13 calls to the above expression can be made and concatenated with `||` in a single IAM condition. So effectively, the limit is 130 roles per IAM resource binding. 

This module works around that by applying the IAM admin binding in multiple bindings of 130 roles. 

The code snippet below shows the behavior in more detail

```terraform
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

  iam_bindings = {
    for index, expression in local.expressions :
    "iam_condition_${index + 1}" => {
      expression = expression
      index      = index + 1
    }
  }
}
```

1. Start with the list of roles to apply
2. Divide up roles into chunks of 10
3. Each chunk of 10 is used to create a condition_string in the format of `"api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])"`
4. Collect up to 13 condition strings per binding -> i.e. effective limit of 130 roles per IAM binding
5. Create IAM binding for each set of 130 roles

### Note 
Some GCP services don't support IAM conditions for delegated role grants. For full list of supported services, see [here](https://cloud.google.com/iam/docs/conditions-attribute-reference#api-attributes-iam)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.18.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.18.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.18.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_project_iam_member.delegated_role_grants](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.direct_role_assignments](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.viewer_group_role_assignment](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |

