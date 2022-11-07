provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket         = var.bucket         # existing s3 bucket name to store terraform state
    key            = var.key            # key in S3 bucket
    region         = var.region         # specify the region name where s3 bucket and DynamoDB table is provisioned for storing terraform state and locks.
    dynamodb_table = var.dynamodb_table # existing DynamoDB Table name to store terraform locks.
    encrypt        = true
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_Subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_Subnet2"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  tags = {
    Name = "Private_Subnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  tags = {
    Name = "Private_Subnet2"
  }
}
