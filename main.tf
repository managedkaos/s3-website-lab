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

resource "aws_iam_user_login_profile" "users" {
  count = var.user_count
  user    = aws_iam_user.users[count.index].name
  password_reset_required = false
}

resource "aws_s3_bucket" "buckets" {
  count = var.user_count
  bucket_prefix = "${aws_iam_user.users[count.index].name}-"

  tags = {
    User = aws_iam_user.users[count.index].name
    Terraform = true
  }
}

resource "aws_iam_policy" "policy" {
  count = var.user_count
  name = aws_s3_bucket.buckets[count.index].id
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
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attachment" {
  count = var.user_count
  user = aws_iam_user.users[count.index].name
  policy_arn = aws_iam_policy.policy[count.index].arn
}

output "user_names" {
  value = zipmap([for u in aws_iam_user.users: u.name], [for p in aws_iam_user_login_profile.users: p.password])
}