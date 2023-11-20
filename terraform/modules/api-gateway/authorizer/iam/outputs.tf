output "invocation_role_arn" {
  value = aws_iam_role.invocation_role.arn
}

output "lambda_role_arn" {
  value = module.lambda_role.role_arn
}
