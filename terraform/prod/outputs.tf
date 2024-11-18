output "project" {
  value = module.project
}

output "project_id" {
  value = module.project.project.project_id
}

output "tag_namespace" {
  value = module.project.docker_repository.namespace
}

output "build_sa" {
  value = module.project.build_sa
}

output "billing_account" {
  value = var.billing_account
}

output "org_id" {
  value = var.org_id
}

output "terraform_sa" {
  value = var.terraform_sa
}