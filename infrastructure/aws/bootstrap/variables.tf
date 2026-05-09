variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "ca-central-1"
}

variable "name_prefix" {
  description = "Prefix used for bootstrap resource names"
  type        = string
  default     = "jellylabs-tofu-state"
}

variable "state_bucket_name" {
  description = "Optional exact S3 state bucket name"
  type        = string
  default     = null
}

variable "lock_table_name" {
  description = "DynamoDB table name for OpenTofu state locking"
  type        = string
  default     = "jellylabs-tofu-locks"
}
