output "rest_api_id" {
  value = module.rest_api.id
}

output "rest_api_stage_name" {
  value = module.rest_api.stage_name
}

output "iot_endpoint" {
  value = data.aws_iot_endpoint.iot.endpoint_address
}
