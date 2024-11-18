terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 1.0"
    }
  }
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_v2_service" "cloudrundemo" {
    name = "cloudrundemo"
    project = data.google_project.project.project_id
    location = var.location
    //the only thing that needs to send messages to this service is
    //the task queue.
    ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    template {
        scaling {
            max_instance_count = 10
            min_instance_count = 0
        }
        containers {
            image = var.image_tag
            resources {
                limits = {
                  cpu = 1
                  memory = ".5Gi"
                }
                startup_cpu_boost = true
            }
        }
    }
    deletion_protection=false
}

resource "google_service_account" "task_submitter" {
  project = data.google_project.project.project_id
  account_id = "cloudrundemo-task-submitter"
  display_name = "cloudrundemo Task Submitter"
  description = "service account for submitting tasks from the service queue to the service."
}

resource "google_project_iam_binding" "enqueuers" {
  project = data.google_project.project.id
  role    = "roles/cloudtasks.enqueuer"

  members = [
    "serviceAccount:${google_service_account.task_submitter.email}"
  ]
}

locals {
    service_uri = provider::corefunc::url_parse(google_cloud_run_v2_service.cloudrundemo.uri)
}

resource "random_string" "random" {
  length           = 4
  special          = false
}

resource "google_cloud_tasks_queue" "cloudrundemo" {
    //if you delete this queue and try to re-create terraform will make
    //you wait to create a new queue of the same name
    name = "cloudrundemo-queue-${random_string.random.result}"
    project = data.google_project.project.project_id
    location = var.location

    http_target {
        http_method = "POST"
        uri_override {
          host = local.service_uri.host
        }
        oidc_token {
            service_account_email = google_service_account.task_submitter.email
        }
    }
}