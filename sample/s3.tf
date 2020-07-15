# # s3.tf
# # 2020/07/15

# # プライベートバケットの定義
# resource "aws_s3_bucket" "private" {
#     bucket = "maaaaakoto-sample-terraform-private"

#     versioning {
#         enabled = true
#     }

#     server_side_encryption_configuration {
#         rule {
#             apply_server_side_encryption_by_default {
#                 sse_algorithm = "AES256"
#             }
#         }
#     }
# }

# # ブロックパブリックアクセスの定義
# resource "aws_s3_bucket_public_access_block" "private" {
#     bucket                      = aws_s3_bucket.private.id
#     block_public_acls           = true
#     block_public_policy         = true
#     ignore_public_acls          = true
#     restrict_public_buckets     = true
# }

# # パブリックバケットの定義
# resource "aws_s3_bucket" "public" {
#     bucket  = "maaaaakoto-sample-terraform-public"
#     acl     = "public-read"

#     cors_rule {
#         allowed_origins = ["https://example.com"]
#         allowed_methods = ["GET"]
#         allowed_headers = ["*"]
#         max_age_seconds = 3000
#     }
# }

# # ALBからのログバケットの定義
# resource "aws_s3_bucket" "alb_log" {
#     bucket = "maaaaakoto-sample-terraform-alb-log"

#     lifecycle_rule {
#         enabled = true

#         expiration {
#             days = "180"
#         }
#     }
# }

# # ログバケッtのポリシーの定義
# resource "aws_s3_bucket_policy" "alb_log" {
#     bucket = aws_s3_bucket.alb_log.id
#     policy = data.aws_iam_policy_document.alb_log.json
# }

# # 59行目の中身
# data "aws_iam_policy_document" "alb_log" {
#     statement {
#         effect      = "Allow"
#         actions     = ["s3:PutObject"]
#         resources   = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

#         principals {
#             type = "AWS"
#             identifiers = ["582318560864"]
#         }
#     }
# }
