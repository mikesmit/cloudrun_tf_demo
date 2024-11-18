module "project" {
  source = "../modules/project"
  stage = "beta"
  org_id = var.org_id
  billing_account = var.billing_account
  terraform_sa = var.terraform_sa
  default_region =  "us-west2"
  bootstrap = var.bootstrap
  cloudrundemo_image_tag = var.cloudrundemo_image_tag
}
