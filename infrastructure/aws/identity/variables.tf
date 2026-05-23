variable "aws_region" {
  description = "AWS region for the main deployment identity and regional lab resources"
  type        = string
  default     = "ca-central-1"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the AWS main deployment role"
  type        = string
  default     = "chris-jelly/jellylabs-dsc"
}

variable "github_main_environment" {
  description = "GitHub Actions environment allowed to assume the AWS main deployment role"
  type        = string
  default     = "aws-production"
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints for the GitHub Actions OIDC provider"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "main_role_name" {
  description = "IAM role name for AWS main OpenTofu deployment from GitHub Actions"
  type        = string
  default     = "jellylabs-tofu-main"
}

variable "plan_role_name" {
  description = "IAM role name for AWS OpenTofu pull request planning from GitHub Actions"
  type        = string
  default     = "jellylabs-tofu-plan"
}

variable "state_bucket_name" {
  description = "Bootstrap-managed S3 bucket used by AWS workload OpenTofu state"
  type        = string
}

variable "state_lock_table_name" {
  description = "Bootstrap-managed DynamoDB table used for OpenTofu state locking"
  type        = string
  default     = "jellylabs-tofu-locks"
}

variable "workload_state_key_prefix" {
  description = "S3 key prefix used by deployable AWS workload root OpenTofu states"
  type        = string
  default     = "aws"
}

variable "lab_resource_prefix" {
  description = "Name prefix for AWS lab resources managed by the main deployment role"
  type        = string
  default     = "jellylabs-"
}

variable "lab_role_prefix" {
  description = "IAM role and policy prefix for lab execution roles managed by the main deployment role"
  type        = string
  default     = "jellylabs-lab-"
}
