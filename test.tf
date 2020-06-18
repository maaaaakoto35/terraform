provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "sandbox" {
  ami = "ami-785c491f"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet.id}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.16.0/20"
  availability_zone = "ap-northeast-1a"
}