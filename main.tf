provider "aws" {}

data "aws_caller_identity" "id" {}

variable "user_count" {
  type = number
  default = 50
  description = "The number of user names to create"
}

resource "random_pet" "users" {
  count  = var.user_count
}

resource "aws_iam_user" "users" {
  count = var.user_count
  name = random_pet.users[count.index].id
}

resource "aws_s3_bucket" "buckets" {
  count = var.user_count
  bucket_prefix = "${aws_iam_user.users[count.index].name}-"

  tags = {
    User = aws_iam_user.users[count.index].name
    Terraform = true
  }
}
