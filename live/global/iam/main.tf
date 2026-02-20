provider "aws" {
    region = "us-east-1"
}

# variable "user_names" {
#     description = "Create IAM users with these names"
#     type = list(string)
#     default = ["neo", "trinity", "morpheus"]
# }

# resource "aws_iam_user" "iam_user" {
#     count = length(var.user_names)
#     name = var.user_names[count.index]
# }

# output "all_usernames" {
#     value = aws_iam_user.iam_user[*].name
# }

module "users" {
    source = "../../../modules/iam"

    count = length(var.user_names)
    user_name = var.user_names[count.index]
}