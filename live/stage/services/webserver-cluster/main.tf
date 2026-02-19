provider "aws" {
    region = var.region
}

terraform {
    backend "s3" {
      bucket = "terraform-up-and-running-1123581321345589"
      key = "stage/services/webserver-cluster/terraform.tfstate"
      region = "us-east-1"

      dynamodb_table = "terraform-up-and-running-locks"
      encrypt = true
    }
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "webservers-stage"
  region = var.region
  remote_state_bucket = var.remote_state_bucket
  db_remote_state_key = var.db_remote_state_key
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}