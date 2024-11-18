output "docker_repository" {
    value = merge({
        namespace = "${google_artifact_registry_repository.docker_repo.location}-docker.pkg.dev/${module.project-factory.project_id}/${google_artifact_registry_repository.docker_repo.name}"
    }, google_artifact_registry_repository.docker_repo)
}

output "region" {
    value = var.default_region
}

output "project" {
    value =  merge(module.project-factory, {
        project_bucket = local.project_bucket
    }) 
}

output "build_sa" {
    value = google_service_account.build-sa.email
}

output "terraform_sa" {
    value = var.terraform_sa
}