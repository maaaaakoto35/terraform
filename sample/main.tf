# main.tf
# 2020/07/03

module "web_server" {
    source          = "./http_server"
    instance_type   = "t3.micro"
}

module "describe_regions_for_ec2" {
    source      = "./iam_role"
    name        = "describe-regions-for-ec2"
    identifier  = "ec2.amazon.com"
    policy      = data.aws_iam_policy_document.allow_describe_regions.json
}

# ポリシードキュメントの定義
data "aws_iam_policy_document" "allow_describe_regions" {
    statement {
        effect      = "Allow"
        actions     = ["ec2:DescriveRegions"]
        resources   = ["*"]
    }
}

output "public_dns" {
    value = module.web_server.public_dns
}