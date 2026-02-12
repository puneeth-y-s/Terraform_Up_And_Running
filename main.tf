provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "example" {
    ami = "ami-05efc83cb5512477c"
    instance_type = "t2.micro"

    tags = {
      Name = "terraform-example"
    }
}