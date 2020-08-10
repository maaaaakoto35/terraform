############################################     main     ############################################
# 2020/07/03

module "web_server" {
    source          = "./http_server"
    instance_type   = "t3.micro"
}

# module "describe_regions_for_ec2" {
#     source      = "./iam_role"
#     name        = "describe-regions-for-ec2"
#     identifier  = "ec2.amazon.com"
#     policy      = data.aws_iam_policy_document.allow_describe_regions.json
# }

# # ポリシードキュメントの定義
# data "aws_iam_policy_document" "allow_describe_regions" {
#     statement {
#         effect      = "Allow"
#         actions     = ["ec2:DescriveRegions"]
#         resources   = ["*"]
#     }
# }

output "public_dns" {
    value = module.web_server.public_dns
}



############################################     s3     ############################################
# 2020/07/15

# プライベートバケットの定義
resource "aws_s3_bucket" "private" {
    bucket = "maaaaakoto-sample-terraform-private"

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

# ブロックパブリックアクセスの定義
resource "aws_s3_bucket_public_access_block" "private" {
    bucket                      = aws_s3_bucket.private.id
    block_public_acls           = true
    block_public_policy         = true
    ignore_public_acls          = true
    restrict_public_buckets     = true
}

# パブリックバケットの定義
resource "aws_s3_bucket" "public" {
    bucket  = "maaaaakoto-sample-terraform-public"
    acl     = "public-read"

    cors_rule {
        allowed_origins = ["https://example.com"]
        allowed_methods = ["GET"]
        allowed_headers = ["*"]
        max_age_seconds = 3000
    }
}

# ALBからのログバケットの定義
resource "aws_s3_bucket" "alb_log" {
    bucket = "maaaaakoto-sample-terraform-alb-log"

    lifecycle_rule {
        enabled = true

        expiration {
            days = "180"
        }
    }
}

# ログバケッtのポリシーの定義
resource "aws_s3_bucket_policy" "alb_log" {
    bucket = aws_s3_bucket.alb_log.id
    policy = data.aws_iam_policy_document.alb_log.json
}

# 59行目の中身
data "aws_iam_policy_document" "alb_log" {
    statement {
        effect      = "Allow"
        actions     = ["s3:PutObject"]
        resources   = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

        principals {
            type = "AWS"
            identifiers = ["582318560864"]
        }
    }
}



############################################     network     ############################################
# 2020/07/15

# VPCの定義
resource "aws_vpc" "example" {
    cidr_block              = "10.0.0.0/16"
    enable_dns_support      = true
    enable_dns_hostnames    = true

    tags = {
        Name = "example"
    }
}

# インターネットゲートウェイの定義
resource "aws_internet_gateway" "example" {
    vpc_id = aws_vpc.example.id
}


############public_0############

# パブリックサブネットの定義
resource "aws_subnet" "public_0" {
    vpc_id                      = aws_vpc.example.id        # 自動振り分け(多分)
    cidr_block                  = "10.0.1.0/24"
    map_public_ip_on_launch     = true
    availability_zone           = "ap-northeast-1a"         # Tokyo
}

# パブリックルートテーブルの定義
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.example.id
}

# パブリックルートの定義
resource "aws_route" "public" {
    route_table_id          = aws_route_table.public.id
    gateway_id              = aws_internet_gateway.example.id
    destination_cidr_block  = "0.0.0.0/0"
}

# パブリックルートテーブルの関連付け
resource "aws_route_table_association" "public_0" {
    subnet_id       = aws_subnet.public_0.id
    route_table_id  = aws_route_table.public.id
}


############private_0############

# プライベートサブネットの定義
resource "aws_subnet" "private_0" {
    vpc_id                      = aws_vpc.example.id
    cidr_block                  = "10.0.65.0/24"
    map_public_ip_on_launch   = false                     # パブリックIPアドレスは不要
    availability_zone           = "ap-northeast-1a"
}

# プライベートルートテーブルの定義
resource "aws_route_table" "private_0" {
    vpc_id = aws_vpc.example.id
}

# プライベートルートテーブルの関連付け
resource "aws_route_table_association" "private_0" {
    subnet_id       = aws_subnet.private_0.id
    route_table_id  = aws_route_table.private_0.id
}


############NATgateway############

# EIPの定義
resource "aws_eip" "nat_gateway_0" {
    vpc         = true
    depends_on  = [aws_internet_gateway.example]
}

# NATゲートウェイの定義
resource "aws_nat_gateway" "example_0" {
    allocation_id   = aws_eip.nat_gateway_0.id
    subnet_id       = aws_subnet.public_0.id
    depends_on      = [aws_internet_gateway.example]
}

# プライベートルートのNATgatewayを利用したルートの定義 -> private_0->internet=true and private_0<-internet=false
resource "aws_route" "private_0" {
    route_table_id          = aws_route_table.private_0.id
    nat_gateway_id          = aws_nat_gateway.example_0.id    # ここが39行目とは違う
    destination_cidr_block  = "0.0.0.0/0"
}


############マルチAZ for 可用性############

# パブリックサブネットの定義
resource "aws_subnet" "public_1" {
    vpc_id                      = aws_vpc.example.id        # 自動振り分け(共通)
    cidr_block                  = "10.0.2.0/24"
    map_public_ip_on_launch   = true
    availability_zone           = "ap-northeast-1c"
}

# パブリックルートテーブルの関連付け
resource "aws_route_table_association" "public_1" {
    subnet_id       = aws_subnet.public_1.id
    route_table_id  = aws_route_table.public.id             # ルートテーブル等は共有
}

# プライベートサブネットの定義
resource "aws_subnet" "private_1" {
    vpc_id                      = aws_vpc.example.id
    cidr_block                  = "10.0.66.0/24"
    map_public_ip_on_launch     = false                     # パブリックIPアドレスは不要
    availability_zone           = "ap-northeast-1c"
}

# EIPの定義
resource "aws_eip" "nat_gateway_1" {
    vpc         = true
    depends_on  = [aws_internet_gateway.example]
}

# NATゲートウェイの定義
resource "aws_nat_gateway" "example_1" {
    allocation_id   = aws_eip.nat_gateway_1.id
    subnet_id       = aws_subnet.public_1.id
    depends_on      = [aws_internet_gateway.example]
}

# プライベートルートテーブルの定義
resource "aws_route_table" "private_1" {
    vpc_id = aws_vpc.example.id
}

resource "aws_route" "private_1" {
    route_table_id          = aws_route_table.private_1.id
    nat_gateway_id          = aws_nat_gateway.example_1.id    # ここが39行目とは違う
    destination_cidr_block  = "0.0.0.0/0"
}

# プライベートルートテーブルの関連付け
resource "aws_route_table_association" "private_1" {
    subnet_id       = aws_subnet.private_1.id
    route_table_id  = aws_route_table.private_1.id
}


############セキュリティグループ############

# セキュリティグループのモジュールの呼び出し
module "example_sg" {
    source          = "./security_group"
    name            = "module_sg"
    vpc_id          = aws_vpc.example.id
    port            = 80
    cidr_blocks     = ["0.0.0.0/0"]
}



############################################     lb     ############################################
# 2020/07/15

# アプリケーションロードバランサーの定義
resource "aws_lb" "example" {
    name                        = "example"
    load_balancer_type          = "application"      # この場合はALB networkの時はNLB
    internal                    = false
    idle_timeout                = 60
    enable_deletion_protection  = false              # demo以外の時はここは true にしておく。(すぐに削除できないように。)

    subnets = [
        aws_subnet.public_0.id,
        aws_subnet.public_1.id,
    ]

    access_logs {
        bucket  = aws_s3_bucket.alb_log.id
        enabled = true
    }

    security_groups = [
        module.http_sg.security_group_id,
        module.https_sg.security_group_id,
        module.http_redirect_sg.security_group_id,
    ]
}

output "alb_dns_name" {
    value = aws_lb.example.arn
}

# ALBのセキュリティグループの定義 (HTTP)
module "http_sg" {
    source      = "./security_group"
    name        = "http-sg"
    vpc_id      = aws_vpc.example.id
    port        = 80
    cidr_blocks = ["0.0.0.0/0"]
}

# ALBのセキュリティグループの定義 (HTTPS)
module "https_sg" {
    source      = "./security_group"
    name        = "https-sg"
    vpc_id      = aws_vpc.example.id
    port        = 443
    cidr_blocks = ["0.0.0.0/0"]
}

# ALBのセキュリティグループの定義 (HTTPからHTTPSへリダイレクト)
module "http_redirect_sg" {
    source      = "./security_group"
    name        = "http-redirect-sg"
    vpc_id      = aws_vpc.example.id
    port        = 8080
    cidr_blocks = ["0.0.0.0/0"]
}

# HTTPリスナーの定義
resource "aws_lb_listener" "http" {
    load_balancer_arn   = aws_lb.example.arn
    port                = "80"
    protocol            = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "これは HTTP です。"
            status_code  = "200"
        }
    }
}

# ホストゾーンのデータソースの定義
data "aws_route53_zone" "example" {
    name = "ksu-unifood.com"        # これだけ本番用
}

# ALBのDNSレコードの定義
resource "aws_route53_record" "example" {
    zone_id = data.aws_route53_zone.example.zone_id
    name    = data.aws_route53_zone.example.name
    type    = "A"

    alias {
        name                    = aws_lb.example.dns_name
        zone_id                 = aws_lb.example.zone_id
        evaluate_target_health  = true
    }
}

output "domain_name" {
    value = aws_route53_record.example.name
}

# ターゲットグループの定義
resource "aws_lb_target_group" "example" {
    name                    = "example"
    target_type             = "ip"
    vpc_id                  = aws_vpc.example.id
    port                    = 80
    protocol                = "HTTP"
    deregistration_delay    = 300

    health_check {
        path                = "/"
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
        matcher             = 200
        port                = "traffic-port"
        protocol            = "HTTP"
    }

    depends_on = [aws_lb.example]
}

# リスナールールの定義
resource "aws_lb_listener_rule" "example" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 100

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.example.arn
    }

    condition {
        path_pattern {
            values = ["*"]
        }
    }
}



############################################     ecs     ############################################
# 2020/07/18

# ECSクラスタの定義
resource "aws_ecs_cluster" "example" {
    name = "example"
}

# タスク定義
resource "aws_ecs_task_definition" "example" {
    family                      = "example"
    cpu                         = "256"
    memory                      = "512"
    network_mode                = "awsvpc"
    requires_compatibilities    = ["FARGATE"]
    container_definitions       = file("./container_definition.json")
    execution_role_arn          = module.ecs_task_execution_role.iam_role_arn
}

# ECSサービスの定義
resource "aws_ecs_service" "example" {
    name                                = "example"
    cluster                             = aws_ecs_cluster.example.arn
    task_definition                     = aws_ecs_task_definition.example.arn
    desired_count                       = 2
    launch_type                         = "FARGATE"
    platform_version                    = "1.3.0"
    health_check_grace_period_seconds   = 60

    network_configuration {
        assign_public_ip = false
        security_groups  = [module.nginx_sg.security_group_id]

        subnets = [
            aws_subnet.private_0.id,
            aws_subnet.private_1.id,
        ]
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.example.arn
        container_name   = "example"
        container_port   = 80
    }

    lifecycle {
        ignore_changes = [task_definition]
    }
}

# ECS用セキュリティグループ
module "nginx_sg" {
    source      = "./security_group"
    name        = "nginx-sg"
    vpc_id      = aws_vpc.example.id
    port        = 80
    cidr_blocks = [aws_vpc.example.cidr_block]
}

# CloudWatch Logsの定義
resource "aws_cloudwatch_log_group" "for_ecs" {
    name              = "/ecs/example"
    retention_in_days = 180
}

# AmazonECSTaskExecutionRolePolicyの参照
data "aws_iam_policy" "ecs_task_execution_role_policy" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSタスク実行IAMロールのポリシードキュメントの定義
data "aws_iam_policy_document" "ecs_task_execution" {
    source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

    statement {
        effect      = "Allow"
        actions     = ["ssm:GetParameters", "kms:Decrypt"]
        resources   = ["*"]
    }
}

# ECSタスク実行IAMロールの定義
module "ecs_task_execution_role" {
    source = "./iam_role"
    name = "ecs-task-execution"
    identifier = "ecs-tasks.amazonaws.com"
    policy = data.aws_iam_policy_document.ecs_task_execution.json
}



