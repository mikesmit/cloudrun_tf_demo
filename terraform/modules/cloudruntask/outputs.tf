output "service"{
  value = google_cloud_run_v2_service.cloudrundemo
}

output "task_queue" {
  value = google_cloud_tasks_queue.cloudrundemo
}

output "submitter_sa" {
  value = google_service_account.task_submitter
}