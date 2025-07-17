output "lambda_role_arn" {
  description = "NAT Gateway制御用のLambda IAMロールのARN"
  value = aws_iam_role.tf_role_lambda_natgateway.arn
}