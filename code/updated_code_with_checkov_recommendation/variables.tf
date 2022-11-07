variable "region" {
  type        = string
  description = "Enter AWS region: "
}

#-------------------KMS Key variables---------------
variable "kms_key_alias" {
  type        = string
  description = "Enter KMS key alias: "
}

variable "kms_account_id" {
  type        = string
  description = "Enter account id where KMS key will be provisioned: "
}

variable "key_admins" {
  type        = list(any)
  description = "Enter list of key admin arns: "
}

#------------------CloudWatch variables-----------------
variable "log_group_name" {
  type        = string
  description = "Enter CloudWatch log group name for VPC flow logs: "
}

variable "retention_in_days" {
  type        = number
  description = "Enter retention period for VPC flow logs stored in CloudWatch logs : "
}

variable "cloudwatch_role" {
  type        = string
  description = "Enter cloudwatch role name : "
}

variable "cloudwatch_role_policy" {
  type        = string
  description = "Enter cloudwatch role policy name : "
}
