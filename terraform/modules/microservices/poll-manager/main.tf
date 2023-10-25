module "poll_manager_workflow" {
  source   = "../../sfn-state-machine"
  name     = "poll-manager"
  type     = "EXPRESS"
  role_arn = var.sfn_role_arn

  definition = <<-EOT
    {
      "Comment": "Poll manager workflow",
      "StartAt": "Choice",
      "States": {
        "Choice": {
          "Type": "Choice",
          "Choices": [
            {
              "Variable": "$.action",
              "StringEquals": "CREATE",
              "Next": "Create"
            },
            {
              "Variable": "$.action",
              "StringEquals": "DELETE",
              "Next": "Delete"
            }
          ],
          "Default": "Fail"
        },
        "Create": {
          "Type": "Succeed"
        },
        "Fail": {
          "Type": "Fail"
        },
        "Delete": {
          "Type": "Succeed"
        }
      }
    }
  EOT
}

module "poll_manager_iam" {
  source  = "./iam"
  sfn_arn = module.poll_manager_workflow.sfn_arn
}

resource "aws_api_gateway_resource" "polls" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "polls"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = var.rest_api_id
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.polls.id
  authorization = "CUSTOM"
  authorizer_id = var.custom_authorizer_id
}

resource "aws_api_gateway_integration" "create_poll" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.polls.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = aws_api_gateway_method.post.http_method
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:us-east-2:states:action/StartSyncExecution"
  credentials             = module.poll_manager_iam.credentials_arn

  request_templates = {
    "application/json" = <<-EOT
      #set($input = $input.json('$'))
      {
        "stateMachineArn": "${module.poll_manager_workflow.sfn_arn}",
        "input": "$util.escapeJavaScript($input).replaceAll("\\'", "'")"
      }
    EOT
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method_response" "post_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "create_poll_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_integration.create_poll.http_method
  status_code = aws_api_gateway_method_response.post_ok.status_code
}
