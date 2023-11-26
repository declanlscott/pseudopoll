output "invoke_arn" {
  value = aws_lambda_function.function.invoke_arn
}

output "arn" {
  value = aws_lambda_function.function.arn
}

output "function_name" {
  value = aws_lambda_function.function.function_name
}
