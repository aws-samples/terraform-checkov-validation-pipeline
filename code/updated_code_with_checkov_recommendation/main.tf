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

resource "aws_kms_key" "kms_key" {
  description         = "KMS key for VPC Flow logs bucket"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_key_policy.json
}

resource "aws_kms_alias" "kms_key_alias" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.kms_key.key_id
}

data "aws_iam_policy_document" "kms_key_policy" {
  version = "2012-10-17"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [var.kms_account_id]
    }
  }
  statement {
    sid = "Allow access for Key Administrators"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = var.key_admins
    }
  }
  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com", "logs.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs_cw" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = aws_kms_key.kms_key.arn
}

resource "aws_iam_role" "cloudwatch_role" {
  name               = var.cloudwatch_role
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_role_trust.json
}

resource "aws_iam_role_policy" "cloudwatch_role_policy" {
  name   = var.cloudwatch_role_policy
  role   = aws_iam_role.cloudwatch_role.id
  policy = data.aws_iam_policy_document.cloudwatch_role_policy_document.json
}

data "aws_iam_policy_document" "cloudwatch_role_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_role_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
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

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.cloudwatch_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs_cw.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Public_Subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
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
