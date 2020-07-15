# # network.tf
# # 2020/07/15

# # VPCの定義
# resource "aws_vpc" "example" {
#     cidr_block              = "10.0.0.0/16"
#     enable_dns_support      = true
#     enable_dns_hostnames    = true

#     tags = {
#         Name = "example"
#     }
# }

# # インターネットゲートウェイの定義
# resource "aws_internet_gateway" "example" {
#     vpc_id = aws_vpc.example.id
# }


# ############public_0############

# # パブリックサブネットの定義
# resource "aws_subnet" "public_0" {
#     vpc_id                      = aws_vpc.example.id        # 自動振り分け(多分)
#     cidr_block                  = "10.0.1.0/24"
#     map_public_ip_on_launch   = true
#     availability_zone           = "ap-northeast-1a"         # Tokyo
# }

# # パブリックルートテーブルの定義
# resource "aws_route_table" "public" {
#     vpc_id = aws_vpc.example.id
# }

# # パブリックルートの定義
# resource "aws_route" "public" {
#     route_table_id          = aws_route_table.public.id
#     gateway_id              = aws_internet_gateway.example.id
#     destination_cidr_block  = "0.0.0.0/0"
# }

# # パブリックルートテーブルの関連付け
# resource "aws_route_table_association" "public_0" {
#     subnet_id       = aws_subnet.public_0.id
#     route_table_id  = aws_route_table.public.id
# }


# ############private_0############

# # プライベートサブネットの定義
# resource "aws_subnet" "private_0" {
#     vpc_id                      = aws_vpc.example.id
#     cidr_block                  = "10.0.65.0/24"
#     map_public_ip_on_launch   = false                     # パブリックIPアドレスは不要
#     availability_zone           = "ap-northeast-1a"
# }

# # プライベートルートテーブルの定義
# resource "aws_route_table" "private_0" {
#     vpc_id = aws_vpc.example.id
# }

# # プライベートルートテーブルの関連付け
# resource "aws_route_table_association" "private_0" {
#     subnet_id       = aws_subnet.private_0.id
#     route_table_id  = aws_route_table.private_0.id
# }


# ############NATgateway############

# # EIPの定義
# resource "aws_eip" "nat_gateway_0" {
#     vpc         = true
#     depends_on  = [aws_internet_gateway.example]
# }

# # NATゲートウェイの定義
# resource "aws_nat_gateway" "example_0" {
#     allocation_id   = aws_eip.nat_gateway_0.id
#     subnet_id       = aws_subnet.public_0.id
#     depends_on      = [aws_internet_gateway.example]
# }

# # プライベートルートのNATgatewayを利用したルートの定義 -> private_0->internet=true and private_0<-internet=false
# resource "aws_route" "private_0" {
#     route_table_id          = aws_route_table.private_0.id
#     nat_gateway_id          = aws_nat_gateway.example_0.id    # ここが39行目とは違う
#     destination_cidr_block  = "0.0.0.0/0"
# }


# ############マルチAZ for 可用性############

# # パブリックサブネットの定義
# resource "aws_subnet" "public_1" {
#     vpc_id                      = aws_vpc.example.id        # 自動振り分け(共通)
#     cidr_block                  = "10.0.2.0/24"
#     map_public_ip_on_launch   = true
#     availability_zone           = "ap-northeast-1c"
# }

# # パブリックルートテーブルの関連付け
# resource "aws_route_table_association" "public_1" {
#     subnet_id       = aws_subnet.public_1.id
#     route_table_id  = aws_route_table.public.id             # ルートテーブル等は共有
# }

# # プライベートサブネットの定義
# resource "aws_subnet" "private_1" {
#     vpc_id                      = aws_vpc.example.id
#     cidr_block                  = "10.0.66.0/24"
#     map_public_ip_on_launch     = false                     # パブリックIPアドレスは不要
#     availability_zone           = "ap-northeast-1c"
# }

# # EIPの定義
# resource "aws_eip" "nat_gateway_1" {
#     vpc         = true
#     depends_on  = [aws_internet_gateway.example]
# }

# # NATゲートウェイの定義
# resource "aws_nat_gateway" "example_1" {
#     allocation_id   = aws_eip.nat_gateway_1.id
#     subnet_id       = aws_subnet.public_1.id
#     depends_on      = [aws_internet_gateway.example]
# }

# # プライベートルートテーブルの定義
# resource "aws_route_table" "private_1" {
#     vpc_id = aws_vpc.example.id
# }

# resource "aws_route" "private_1" {
#     route_table_id          = aws_route_table.private_1.id
#     nat_gateway_id          = aws_nat_gateway.example_1.id    # ここが39行目とは違う
#     destination_cidr_block  = "0.0.0.0/0"
# }

# # プライベートルートテーブルの関連付け
# resource "aws_route_table_association" "private_1" {
#     subnet_id       = aws_subnet.private_1.id
#     route_table_id  = aws_route_table.private_1.id
# }


# ############セキュリティグループ############

# # セキュリティグループのモジュールの呼び出し
# module "example_sg" {
#     source          = "./security_group"
#     name            = "module_sg"
#     vpc_id          = aws_vpc.example.id
#     port            = 80
#     cidr_blocks     = ["0.0.0.0/0"]
# }