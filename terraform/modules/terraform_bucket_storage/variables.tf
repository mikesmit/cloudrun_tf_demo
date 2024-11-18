variable "bucket" {
    type = string
    description = "the bucket to store terraform state in"
}

variable "path" {
    type = string
    description = "the path in the bucket to use for terraform state. Must be unique in the project."
}