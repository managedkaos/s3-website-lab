provider "aws" {}

data "aws_caller_identity" "id" {}

variable "user_count" {
  type        = number
  default     = 5
  description = "The number of user names to create"
}

locals {
  tags = {
    Author    = data.aws_caller_identity.id.arn
    Project   = "s3-website-lab"
    Terraform = true
  }
}

resource "random_pet" "users" {
  count = var.user_count
}

resource "aws_iam_user" "users" {
  count = var.user_count
  name  = random_pet.users[count.index].id
  tags = local.tags
}

resource "aws_iam_user_login_profile" "users" {
  count                   = var.user_count
  user                    = aws_iam_user.users[count.index].name
  password_reset_required = false
}

resource "aws_s3_bucket" "buckets" {
  count         = var.user_count
  bucket_prefix = "${aws_iam_user.users[count.index].name}-"
  force_destroy = true
  tags = local.tags

}

resource "aws_iam_policy" "policy" {
  count = var.user_count
  name  = aws_s3_bucket.buckets[count.index].id
  tags = local.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:*"
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.buckets[count.index].arn,
          "${aws_s3_bucket.buckets[count.index].arn}/*"
        ]
      },
      {
        Action = [
          "s3:DeleteBucket"
        ],
        Effect = "Deny",
        Resource = [
          "arn:aws:s3:::*"
        ]
      },
      {
        Action = ["s3:ListAllMyBuckets"],
        Effect = "Allow",
        Resource : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attachment" {
  count      = var.user_count
  user       = aws_iam_user.users[count.index].name
  policy_arn = aws_iam_policy.policy[count.index].arn
}

output "user_names" {
  value = [for u in aws_iam_user.users : u.name]
}
