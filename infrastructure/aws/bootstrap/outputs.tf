output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

output "region" {
  value = var.aws_region
}

output "bootstrap_state_key" {
  value = "aws/bootstrap/global.tfstate"
}

output "lock_table" {
  value = aws_dynamodb_table.state_lock.name
}
