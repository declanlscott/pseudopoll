output "vote_result_publisher_lambda_function_name" {
  value = module.vote_result_publisher_lambda.function_name
}

output "vote_result_publisher_lambda_arn" {
  value = module.vote_result_publisher_lambda.arn
}

output "vote_result_publisher_lambda_alias_name" {
  value = aws_lambda_alias.vote_result_publisher_alias.name
}

output "vote_count_publisher_lambda_function_name" {
  value = module.vote_count_publisher_lambda.function_name
}

output "vote_count_publisher_lambda_arn" {
  value = module.vote_count_publisher_lambda.arn
}

output "vote_count_publisher_lambda_alias_name" {
  value = aws_lambda_alias.vote_count_publisher_alias.name
}

output "poll_modification_publisher_lambda_function_name" {
  value = module.poll_modification_publisher_lambda.function_name
}

output "poll_modification_publisher_lambda_arn" {
  value = module.poll_modification_publisher_lambda.arn
}

output "poll_modification_publisher_lambda_alias_name" {
  value = aws_lambda_alias.poll_modification_publisher_alias.name
}
