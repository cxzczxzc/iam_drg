terraform {
  backend "remote" {
    organization = "[your-organization]"

    workspaces {
      prefix = "[your-terraform-cloud-workspace]"
    }
  }
}