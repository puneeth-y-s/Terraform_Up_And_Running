variable "remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type = string
  default = "terraform-up-and-running-1123581321345589"
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type = string
  default = "stage/data-stores/mysql/terraform.tfstate"
}

variable "region" {
  description = "The AWS region to deploy resources"
  type = string
  default = "us-east-1"
}
