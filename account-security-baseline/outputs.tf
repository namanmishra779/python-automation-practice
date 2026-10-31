output "aws_account_id" {
  description = "Account where the baseline is deployed."
  value       = data.aws_caller_identity.current.account_id
}

output "cloudtrail_bucket_name" {
  description = "Private S3 bucket receiving CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_name" {
  description = "Multi-region CloudTrail trail name."
  value       = aws_cloudtrail.baseline.name
}

output "secret_arn" {
  description = "ARN of the encrypted secret. Its value is intentionally not managed by Terraform."
  value       = aws_secretsmanager_secret.app_db.arn
}

output "app_role_arn" {
  description = "ARN of the EC2 role scoped to the application secret."
  value       = aws_iam_role.app.arn
}

output "app_instance_profile_name" {
  description = "Instance profile to attach to an application EC2 instance."
  value       = aws_iam_instance_profile.app.name
}

output "developers_group_name" {
  description = "Group with EC2 describe access and optional scoped S3 read access."
  value       = aws_iam_group.developers.name
}

output "guardduty_detector_id" {
  description = "Detector ID when GuardDuty is enabled; otherwise null."
  value       = var.enable_guardduty ? aws_guardduty_detector.baseline[0].id : null
}
