module "poll_manager_workflow" {
  source   = "../../sfn-state-machine"
  name     = "poll-manager"
  role_arn = var.sfn_role_arn

  definition = <<EOF
  {
    "Comment": "Poll manager workflow",
    "StartAt": "Pass",
    "States": {
      "Pass": {
        "Type": "Pass",
        "End": true,
        "Result": {
          "hello": "world"
        }
      }
    }
  }
  EOF
}

module "poll_manager_iam" {
  source  = "./iam"
  sfn_arn = module.poll_manager_workflow.sfn_arn
}

module "create_poll_route" {
  source              = "../../api-gateway/route"
  api_id              = var.api_id
  route_key           = "POST /polls"
  integration_subtype = "StepFunctions-StartExecution"
  credentials_arn     = module.poll_manager_iam.credentials_arn

  request_parameters = {
    StateMachineArn = module.poll_manager_workflow.sfn_arn
  }
}
