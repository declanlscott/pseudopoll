output "id" {
  value = aws_api_gateway_rest_api.rest_api.id
}

output "root_resource_id" {
  value = aws_api_gateway_rest_api.rest_api.root_resource_id
}

output "stage_name" {
  value = aws_api_gateway_stage.v1.stage_name
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.rest_api.execution_arn
}
