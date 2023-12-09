output "role_name" {
  value = aws_iam_role.api_gateway_role.name
}

output "role_arn" {
  value = aws_iam_role.api_gateway_role.arn
}
