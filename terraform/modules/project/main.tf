provider "google" {
  impersonate_service_account = var.terraform_sa
  region = var.default_region
}

provider "google-beta" {
  impersonate_service_account = var.terraform_sa
  region = var.default_region
}

module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 17.0"

  name                 = "cloudrun-demo-${var.stage}"
  random_project_id    = true
  org_id               = var.org_id
  billing_account      = var.billing_account
  bucket_project       = "cloudrun-demo-${var.stage}"
  //necessary to keep the compute user around for builds...
  default_service_account = "keep" //https://github.com/terraform-google-modules/terraform-google-project-factory/blob/master/docs/TROUBLESHOOTING.md#cannot-deploy-app-engine-flex-application
  //artifact registry so we can store docker images
  //cloudbuild so we can build docker images
  //run to execute google run containers
  //cloudtasks to put the run container behind a task queue
  activate_apis = [ "artifactregistry.googleapis.com", "cloudbuild.googleapis.com", "run.googleapis.com", "cloudtasks.googleapis.com" ]
}

locals {
  default_compute_user = "${module.project-factory.project_number}-compute@developer.gserviceaccount.com"
}

data "google_service_account" "default_compute_sa" {
  account_id = local.default_compute_user
  depends_on = [ module.project-factory]
}

//as of may 2025 the compute service account does not come with default permissions so you have
//to add them. NOTE: Given this, maybe we should disable it above and just make a new one, but
//this works.
//google_project_iam_member is non-authoritative and will add the role to this member without removing it from any other members.
//found these two roles based on experimentation with glcoud builds submit
resource "google_project_iam_member" "compute_service_account_roles" {
  for_each = toset(["roles/logging.logWriter", "roles/storage.admin", "roles/artifactregistry.writer"])
  project = module.project-factory.project_id
  role = each.key
  member = "serviceAccount:${data.google_service_account.default_compute_sa.email}"
}

resource "google_artifact_registry_repository" "docker_repo" {
    repository_id = "${module.project-factory.project_id}-repo"
    description = "Docker repo for images created under the ${module.project-factory.project_name} project"
    format = "DOCKER"
    project = module.project-factory.project_id
}

//service account for building stuff
resource "google_service_account" "build-sa" {
  project = module.project-factory.project_id
  account_id = "build-${module.project-factory.project_id}"
  description = "service account for starting artifact builds."
}

//Needs to be able to submit builds.
resource "google_project_iam_member" "build-service-account-roles" {
  for_each = toset(["roles/cloudbuild.builds.builder"])
  project = module.project-factory.project_id
  role = each.key
  member = "serviceAccount:${google_service_account.build-sa.email}"
}

//and also in turn, needs to be able to use the compute service account.
resource "google_service_account_iam_binding" "compute-service-iam" {
  service_account_id = data.google_service_account.default_compute_sa.id
  role               = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.build-sa.email}"
  ]
}

//now the actual services. 
module "cloudruntask" {
  count = var.bootstrap ? 0 : 1
  source="../cloudruntask"
  image_tag = var.cloudrundemo_image_tag
  location = var.default_region
  project_id = module.project-factory.project_id
}

locals {
  //for some reason they don't export the bucket, just the url. And that as an array.
  //pull the one and only one bucket url and get the bucket name
  project_bucket = trimprefix(module.project-factory.project_bucket_url[0], "gs://")
}

module "terraform_bucket_storage" {
  source = "../terraform_bucket_storage"
  bucket = local.project_bucket
  path = "project/"
}
