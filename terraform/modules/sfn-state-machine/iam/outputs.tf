output "role_arn" {
  value = aws_iam_role.iam_for_sfn.arn
}

output "role_name" {
  value = aws_iam_role.iam_for_sfn.name
}
