variable "terraform_sa" {
  type = string
  description = "The email for the terraform service account from the seed project. terraform will attempt to impersonate this account."
}

variable "default_region" {
    type = string
    description = "the default region to use in the provider"
}

variable "org_id" {
    type = string
    description = "The organization ID of the organization to add the new project to"
}

variable "billing_account" {
    type = string
    description = "The billing account to associated with the new project"
}

variable "stage" {
    type = string
    validation {
        condition = contains(["prod", "beta"], var.stage)
        error_message = "stage must be one of 'prod' or 'beta'"
    }
}

variable "bootstrap" {
    type = bool
    default = false
    description = "in order to actually build an image we can deploy, we'll need to run this as 'bootstrap' once"
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
