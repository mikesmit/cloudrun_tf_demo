//https://cloud.google.com/docs/terraform/resource-management/store-state
resource "local_file" "default" {
  file_permission = "0644"
  filename        = "${path.cwd}/backend.tf"
  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${var.bucket}"
      prefix = "terraform/state/${var.path}"
    }
  }
  EOT
}