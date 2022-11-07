variable "region" {
  type        = string
  description = "Enter AWS region where terraform scripts will be deployed: "
}

variable "terraform_state_bucket_name" {
  type        = string
  description = "Enter bucket name to store terraform state: "
}

variable "terraform_locks_ddb_table_name" {
  type        = string
  description = "Enter DynamoDB table name to store terrafrom locks: "
}
