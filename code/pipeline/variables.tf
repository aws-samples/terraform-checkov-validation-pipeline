variable "region" {
  type        = string
  description = "Enter AWS region: "
}

variable "codecommit_repository_name" {
  type        = string
  description = "Enter codecommit repository name: "
}

variable "codebuild_service_role_name" {
  type        = string
  description = "Enter the name for codebuild service role: "
}

variable "codebuild_service_role_permissions" {
  type        = list(any)
  description = "Enter the codebuild service role permissions: "
}

variable "terraform_validation_project_name" {
  type        = string
  description = "Enter the codebuild project name: "
}

variable "terraform_validation_project_description" {
  type        = string
  description = "Enter the codebuild project description: "
}

variable "codebuild_compute_type" {
  type        = string
  description = "Enter the codebuild environment's compute type: "
}

variable "codebuild_image" {
  type        = string
  description = "Enter the codebuild environment's image: "
}

variable "codebuild_image_pull_credentials_type" {
  type        = string
  description = "Enter the codebuild environment's image pull credentials type: "
}

variable "codebuild_os_type" {
  type        = string
  description = "Enter the codebuild environment's os type: "
}

variable "codebuild_deploy_project_name" {
  type        = string
  description = "Enter the codebuild project name: "
}

variable "codebuild_deploy_project_description" {
  type        = string
  description = "Enter the codebuild project description: "
}

variable "validation_error_notification" {
  type        = string
  description = "Enter the email to receive notification for terraform validation errors: "
}

variable "terraform_validation_result_bucket_name" {
  type        = string
  description = "Enter the bucket name that will store the checkov results: "
}

variable "sns_topic_name" {
  type        = string
  description = "Enter the SNS topic name: "
}

variable "email_notification_endpoint" {
  type        = string
  description = "Enter the email address for notification: "
}

variable "codepipeline_service_role_name" {
  type        = string
  description = "Enter the name for codebuild service role: "
}

variable "codepipeline_name" {
  type        = string
  description = "Enter the name for codebuild service role: "
}

variable "codepipeline_artifact_bucket" {
  type        = string
  description = "Enter the bucket name for CodePipeline artifact: "
}

variable "lambda_role" {
  type        = string
  description = "Enter lambda role name"
}

variable "cw_event_role" {
  type        = string
  description = "Enter cloudwatch event role name"
}
