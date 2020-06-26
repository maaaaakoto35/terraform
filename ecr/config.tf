# config.tf
# terraformで管理するインフラの情報を保存するバケット(S3)を指定

terraform {
      backend "s3" {
        bucket = "unifood-dev"  # 個人で作成したS3のバケット名
        key = "sample/ecr/terraform.tfstate"
        region = "ap-northeast-1"
    }
}

# providerはAWSでregionをTOKYOを指定
provider "aws" {
    region = "ap-northeast-1"
}