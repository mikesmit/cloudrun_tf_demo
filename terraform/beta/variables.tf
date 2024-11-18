variable "org_id" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "bootstrap" {
    type = bool
    default = false
    description = "in order to actually build an image we can deploy, we'll need to run this as 'bootstrap' once"
}

variable "terraform_sa" {
  type = string
  description = "the service account associated with your seed project"
}

variable "cloudrundemo_image_tag" {
    type = string
    default = null
    validation {
      condition = var.bootstrap || var.cloudrundemo_image_tag != null
      error_message = "Unless you are running a bootstrap you must provide a cloudrundemo_image_tag"
    }
    description = "the image to deploy for the cloudrundemo. Null if we're bootstrapping"
}
