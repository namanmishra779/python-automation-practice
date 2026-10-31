# AWS Account Security Baseline

A Terraform implementation of the Session 12 account-security project. It creates a private, encrypted CloudTrail log bucket and multi-region trail; a Secrets Manager secret encrypted with the AWS-managed KMS key; an EC2 role and instance profile that can read only that secret; and a read-only developers group with optional bucket-scoped S3 access. GuardDuty and the example IAM user are opt-in.

Root MFA, root access-key removal, and organization SCPs are deliberately documented as operator actions. Terraform does not attempt to manage root credentials or attach an organization-wide guardrail.

## Safety Notes

- Start in a personal sandbox account with a billing alarm. Confirm the AWS account and region before applying.
- The secret value is not set by Terraform. Terraform state therefore does not contain the secret payload.
- The secret uses the AWS-managed `aws/secretsmanager` KMS key by default. This avoids creating a separately billed customer-managed KMS key.
- GuardDuty is disabled by default. It can incur charges after the free trial; set `enable_guardduty = true` only when you intend to use it.
- CloudTrail log objects are configured to expire after 90 days by default. Adjust retention to your audit requirements.
- Terraform state can contain sensitive infrastructure metadata. Keep it private; do not commit state, plans, credentials, or secret files.
- Review `terraform plan` carefully. `terraform destroy` removes the trail and monitoring resources and should only be used in a disposable practice account.

## Prerequisites

- Terraform 1.6 or newer
- AWS CLI v2
- An AWS sandbox account
- An operator identity with the required IAM, CloudTrail, S3, Secrets Manager, and (if opted in) GuardDuty permissions

Prefer IAM Identity Center / AWS SSO for human access. Do not use root for daily work or create long-lived access keys.

## 1. Lock Down Root Manually

Sign in as the root user only for account-level setup:

1. Enable MFA, preferably with a hardware security key where available.
2. Delete any root access keys.
3. Store root recovery information securely and sign out.
4. Use a separate federated administrator identity for the remaining setup.
5. Set a billing alarm before enabling paid services.

Confirm the active identity and region before proceeding:

```powershell
aws sts get-caller-identity
aws configure list
```

The account ID returned must be the sandbox account you intend to modify.

## 2. Configure and Review Terraform

From this directory:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out baseline.tfplan
```

Review the plan for the correct account, region, resource names, retention period, and optional features. Then apply the reviewed plan:

```powershell
terraform apply baseline.tfplan
```

The plan creates a CloudTrail trail and S3 bucket, IAM group and role, instance profile, and a Secrets Manager secret. It does not create EC2 instances or grant a human login. Set `developer_s3_bucket_arns` only to buckets developers should read. Set `create_example_iam_user = true` only for isolated practice; the user gets no keys or console password. Enable GuardDuty only when you accept its potential charges.

## 3. Add a Secret Value Outside Terraform

Terraform creates the secret container, but not its value. This keeps the payload out of Terraform state. Create a local file named `secret.json` with the application secret, then run:

```powershell
$secretArn = terraform output -raw secret_arn
aws secretsmanager put-secret-value --secret-id $secretArn --secret-string file://secret.json
Remove-Item secret.json
```

`secret*.json` is ignored by Git. Never paste a real secret into a committed `.tf` or `.tfvars` file.

## 4. Attach the Role and Prove Its Scope

Attach the output instance profile to the intended EC2 instance using the console or a separately reviewed deployment. The role trust policy limits assumption to EC2 instances in this account and region.

Check that the expected secret is allowed:

```powershell
$roleArn = terraform output -raw app_role_arn
$secretArn = terraform output -raw secret_arn
aws iam simulate-principal-policy --policy-source-arn $roleArn --action-names secretsmanager:GetSecretValue --resource-arns $secretArn --query "EvaluationResults[].EvalDecision"
```

Expected: `allowed`.

Check that another secret and unrelated actions are denied:

```powershell
aws iam simulate-principal-policy --policy-source-arn $roleArn --action-names secretsmanager:GetSecretValue --resource-arns "arn:aws:secretsmanager:ap-south-1:ACCOUNT_ID:secret:other-secret-xxxxxx" --query "EvaluationResults[].EvalDecision"
aws iam simulate-principal-policy --policy-source-arn $roleArn --action-names s3:GetObject --resource-arns "arn:aws:s3:::example-bucket/example-object" --query "EvaluationResults[].EvalDecision"
aws iam simulate-principal-policy --policy-source-arn $roleArn --action-names ec2:TerminateInstances --resource-arns "*" --query "EvaluationResults[].EvalDecision"
```

Expected: `implicitDeny` for each. Replace `ACCOUNT_ID` and the example ARN with valid ARNs in your test account. The IAM simulator evaluates policies but does not replace an end-to-end runtime test from an EC2 instance.

## 5. Verify Detection and Audit

```powershell
aws cloudtrail get-trail-status --name (terraform output -raw cloudtrail_name) --query IsLogging
aws cloudtrail get-trail --name (terraform output -raw cloudtrail_name)
terraform output guardduty_detector_id
```

Expected: CloudTrail reports `true` for `IsLogging`. The GuardDuty output is `null` unless you enabled it. New trail events can take several minutes to appear.

The account credential report can help verify IAM-user MFA, but it does not prove root MFA. Verify root MFA in the account security settings.

## 6. Organization SCP Example

`policies/guardrail-scp.example.json` is an example only. SCPs require AWS Organizations, must be attached from the management/delegated administrator account, and can lock out workloads if region exceptions are incomplete. Review service-linked-role and global-service behavior, test in a non-production OU, and retain a recovery path before attaching any SCP. An SCP limits permissions; it does not grant them.

## Cleanup

Empty the dedicated CloudTrail bucket only after exporting or discarding its practice logs. Then destroy the stack:

```powershell
terraform destroy
```

Terraform schedules secret deletion using `secret_recovery_days` (7 days by default). For an isolated practice secret, set `secret_recovery_days = 0` in `terraform.tfvars` before destroying if you explicitly want immediate, irreversible deletion. Confirm the CloudTrail bucket is empty before destroying; Terraform cannot delete a non-empty S3 bucket automatically. GuardDuty is removed by Terraform when it was enabled.

## GitHub

Commit this directory to a dedicated repository. Keep `.terraform/`, state files, plans, `terraform.tfvars`, and secret files out of Git. For team or production use, move state to a private, encrypted remote backend with locking before applying from multiple machines.
