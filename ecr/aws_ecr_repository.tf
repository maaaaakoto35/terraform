# aws_ecr_repository.tf
# this source is for ECR at AWS

# ECRのイメージ名を指定
resource "aws_ecr_repository" "sample-image" {
    name = "unifood-dev"
}