variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "dynamodb_table" {
  description = "DynamoDB table name for state locking"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment (e.g. dev, prod)"
  type        = string
  default     = "dev"
}
