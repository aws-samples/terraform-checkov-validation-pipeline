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

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_codecommit_repository" "codecommit_repository" {
  repository_name = var.codecommit_repository_name
  description     = "This respository stores terraform scripts for infrastructure provisioning"
}

resource "aws_iam_role" "codebuild_service_role" {
  name                = var.codebuild_service_role_name
  assume_role_policy  = data.aws_iam_policy_document.codebuild_service_role_trust.json
  managed_policy_arns = var.codebuild_service_role_permissions
}

data "aws_iam_policy_document" "codebuild_service_role_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket" "terraform_validation_result" {
  bucket = var.terraform_validation_result_bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_validation_result_encryption_configuration" {
  bucket = aws_s3_bucket.terraform_validation_result.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_codebuild_project" "terraform_validation" {
  name         = var.terraform_validation_project_name
  description  = var.terraform_validation_project_description
  service_role = aws_iam_role.codebuild_service_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = var.codebuild_os_type
    image_pull_credentials_type = var.codebuild_image_pull_credentials_type
    environment_variable {
      name  = "TERRAFORM_VALIDATION_RESULT_BUCKET"
      value = "s3://${aws_s3_bucket.terraform_validation_result.id}/"
    }
  }
  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec_terraform_validation.yml")
  }
}

resource "aws_codebuild_project" "terraform_deploy" {
  name         = var.codebuild_deploy_project_name
  description  = var.codebuild_deploy_project_description
  service_role = aws_iam_role.codebuild_service_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = var.codebuild_os_type
    image_pull_credentials_type = var.codebuild_image_pull_credentials_type
  }
  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec_deploy.yml")
  }
}

resource "aws_iam_role" "codepipeline_service_role" {
  name                = var.codepipeline_service_role_name
  assume_role_policy  = data.aws_iam_policy_document.codepipeline_service_role_trust.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeCommitFullAccess", "arn:aws:iam::aws:policy/IAMFullAccess", "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess", "arn:aws:iam::aws:policy/AmazonSNSFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess"]
}

data "aws_iam_policy_document" "codepipeline_service_role_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket" "codepipeline_artifact" {
  bucket = var.codepipeline_artifact_bucket
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifact_encryption_configuration" {
  bucket = aws_s3_bucket.codepipeline_artifact.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_sns_topic" "approval_request" {
  display_name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "approval_request_subscription" {
  topic_arn = aws_sns_topic.approval_request.arn
  protocol  = "email"
  endpoint  = var.email_notification_endpoint
}

resource "aws_codepipeline" "codepipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.codepipeline_service_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifact.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName = var.codecommit_repository_name
        BranchName     = "main"
      }
    }
  }
  stage {
    name = "Validate"
    action {
      name            = "Terraform_Validate"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.terraform_validation.id
      }
    }
  }
  stage {
    name = "Approve-Reject"
    action {
      name     = "Manual_Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
      configuration = {
        NotificationArn    = aws_sns_topic.approval_request.arn
        ExternalEntityLink = "https://s3.console.aws.amazon.com/s3/object/${aws_s3_bucket.terraform_validation_result.id}?region=${data.aws_region.current.name}&prefix=plan_output.json"
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Terraform_Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.terraform_deploy.id
      }
    }
  }
}

resource "aws_ses_email_identity" "notify_validation_errors" {
  email = var.validation_error_notification
}

resource "aws_iam_role" "lambda_permission" {
  name                = var.lambda_role
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonSESFullAccess", "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"]
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "send_notification" {
  filename         = "lambda_function_payload.zip"
  function_name    = "terraform_validation_failure_notification"
  role             = aws_iam_role.lambda_permission.arn
  handler          = "lambda_function_payload.lambda_handler"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  runtime          = "python3.7"
  environment {
    variables = {
      SENDER      = var.validation_error_notification,
      RECIPIENT   = var.validation_error_notification
      REGION      = data.aws_region.current.name
      BUCKET_NAME = var.terraform_validation_result_bucket_name
    }
  }
}

resource "aws_iam_role" "event_permission" {
  name = var.cw_event_role

  inline_policy {
    name = "lambda_invoke_permission"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["lambda:invoke"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_event_rule" "validation_failed" {
  name        = "validation_failed_rule"
  description = "This event rule will be triggered for terraform validation failed"
  role_arn    = aws_iam_role.event_permission.arn
  event_pattern = jsonencode(
    {
      source      = ["aws.codebuild"],
      detail-type = ["CodeBuild Build State Change"],
      resources   = ["${aws_codebuild_project.terraform_validation.arn}:*"],
      detail = {
        build-status = [
          "FAILED"
        ]
      }
    }
  )
}

resource "aws_cloudwatch_event_target" "send_notification" {
  rule = aws_cloudwatch_event_rule.validation_failed.name
  arn  = aws_lambda_function.send_notification.arn
}
