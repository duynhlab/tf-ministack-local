# ---------------------------------------------------------------------------
# Outputs — Go BE → S3 Compute Matrix
# ---------------------------------------------------------------------------

output "bucket_same_region_arn" {
  value = aws_s3_bucket.same_region.arn
}

output "bucket_cross_region_arn" {
  value = aws_s3_bucket.cross_region.arn
}

output "bucket_cross_account_arn" {
  value = aws_s3_bucket.cross_account.arn
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_app.arn
}

output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_app.name
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "ecs_exec_role_arn" {
  value = aws_iam_role.ecs_exec.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_app.arn
}

output "cross_account_data_reader_arn" {
  description = "Target role in Account B; Go SDK calls sts:AssumeRole on this ARN with ExternalId"
  value       = aws_iam_role.cross_account_data_reader.arn
}

output "cross_account_external_id" {
  value     = var.external_id
  sensitive = true
}
