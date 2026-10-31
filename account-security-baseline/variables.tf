variable "aws_region" {
  description = "AWS region for the baseline resources."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Lowercase prefix used for resource names and tags."
  type        = string
  default     = "account-security-baseline"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "project_name must be 3-31 lowercase letters, digits, or hyphens and start with a letter."
  }
}

variable "trail_name" {
  description = "Name of the multi-region CloudTrail trail."
  type        = string
  default     = "account-security-baseline"
}

variable "secret_name" {
  description = "Name of the application secret."
  type        = string
  default     = "prod/db"
}

variable "secret_recovery_days" {
  description = "Days before a deleted secret is permanently removed. Set to 0 for immediate deletion."
  type        = number
  default     = 7

  validation {
    condition     = var.secret_recovery_days == 0 || (var.secret_recovery_days >= 7 && var.secret_recovery_days <= 30)
    error_message = "secret_recovery_days must be 0 or between 7 and 30."
  }
}

variable "cloudtrail_retention_days" {
  description = "Number of days to retain CloudTrail logs in S3."
  type        = number
  default     = 90

  validation {
    condition     = var.cloudtrail_retention_days >= 1
    error_message = "cloudtrail_retention_days must be at least 1."
  }
}

variable "developer_s3_bucket_arns" {
  description = "S3 bucket ARNs developers may list and read, for example arn:aws:s3:::team-data. Empty means no S3 access."
  type        = list(string)
  default     = []
}

variable "create_example_iam_user" {
  description = "Create an IAM user with no access keys or console password, for isolated practice only. Prefer IAM Identity Center for people."
  type        = bool
  default     = false
}

variable "example_iam_user_name" {
  description = "Name of the optional example IAM user."
  type        = string
  default     = "alice"
}

variable "enable_guardduty" {
  description = "Enable GuardDuty in this region. GuardDuty can incur charges after its free trial."
  type        = bool
  default     = false
}
