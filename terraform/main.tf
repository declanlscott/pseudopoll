terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.20.1"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.4.0"
    }
  }

  ###################################################################
  ## After running `terraform apply` (with local backend)
  ## you will uncomment this block and then re-run `terraform init`
  ## to switch from local backend to remote AWS backend
  ###################################################################
  backend "s3" {
    bucket         = "pseudopoll-tf-state"
    key            = "tf-bootstrap/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "pseudopoll-tf-state-locking"
    encrypt        = true
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-2"
}

provider "archive" {
  # Configuration options
}

module "remote_backend" {
  source = "./modules/remote-backend"
}

resource "aws_route53_zone" "zone" {
  name = var.domain_name
}

module "api_gateway_iam" {
  source = "./modules/api-gateway/iam"
}

module "rest_api" {
  source      = "./modules/api-gateway"
  name        = "pseudopoll-rest-api"
  domain_name = var.domain_name
  zone_id     = aws_route53_zone.zone.zone_id

  redeployment_trigger_hashes = concat([
    module.api_authorizer.resources_hash,
    module.poll_manager_microservice.resources_hash,
    module.vote_queue_microservice.resources_hash,
    local.resources_hash,
  ])
}

locals {
  region = "us-east-2"
  resources_hash = sha1(jsonencode([
    aws_api_gateway_model.poll,
    aws_api_gateway_model.create_poll,
    aws_api_gateway_model.archive_poll,
    aws_api_gateway_model.update_poll_duration,
    aws_api_gateway_model.error,
  ]))
}

module "lambda_logging" {
  source = "./modules/lambda/logs"
}

module "api_authorizer" {
  source                    = "./modules/api-gateway/authorizer"
  name                      = "pseudopoll-authorizer"
  function_name             = "pseudopoll-authorizer"
  rest_api_id               = module.rest_api.id
  archive_source_file       = "${path.module}/../backend/lambdas/authorizer/bin/bootstrap"
  archive_output_path       = "${path.module}/../backend/lambdas/authorizer/bin/authorizer.zip"
  jwks_uri                  = var.jwks_uri
  audience                  = var.audience
  token_issuer              = var.token_issuer
  lambda_logging_policy_arn = module.lambda_logging.policy_arn
}

resource "aws_api_gateway_model" "poll" {
  rest_api_id  = module.rest_api.id
  name         = "Poll"
  description  = "Poll schema"
  content_type = "application/json"

  schema = templatefile(
    "./modules/templates/models/poll.json",
    { nanoIdLength = var.nanoid_length }
  )
}

resource "aws_api_gateway_model" "create_poll" {
  rest_api_id  = module.rest_api.id
  name         = "CreatePoll"
  description  = "Create poll schema"
  content_type = "application/json"

  schema = templatefile(
    "./modules/templates/models/create-poll.json",
    {
      promptMinLength = var.prompt_min_length
      promptMaxLength = var.prompt_max_length
      optionMinLength = var.option_min_length
      optionMaxLength = var.option_max_length
      minOptions      = var.min_options
      maxOptions      = var.max_options
      minDuration     = var.min_duration
      maxDuration     = var.max_duration
    }
  )
}

resource "aws_api_gateway_model" "archive_poll" {
  rest_api_id  = module.rest_api.id
  name         = "ArchivePoll"
  description  = "Archive poll schema"
  content_type = "application/json"

  schema = templatefile("./modules/templates/models/archive-poll.json", {})
}

resource "aws_api_gateway_model" "update_poll_duration" {
  rest_api_id  = module.rest_api.id
  name         = "UpdatePollDuration"
  description  = "Update poll duration schema"
  content_type = "application/json"

  schema = templatefile("./modules/templates/models/update-poll-duration.json", {})
}

resource "aws_api_gateway_model" "error" {
  rest_api_id  = module.rest_api.id
  name         = "Error"
  description  = "Error schema"
  content_type = "application/json"

  schema = templatefile("./modules/templates/models/error.json", {})
}

resource "aws_dynamodb_table" "single_table" {
  name         = "pseudopoll-single-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

module "choreography" {
  source         = "./modules/choreography"
  ddb_stream_arn = aws_dynamodb_table.single_table.stream_arn
}

module "poll_manager_microservice" {
  source                          = "./modules/microservices/poll-manager"
  rest_api_id                     = module.rest_api.id
  rest_api_execution_arn          = module.rest_api.execution_arn
  stage_name                      = module.rest_api.stage_name
  poll_model_name                 = aws_api_gateway_model.poll.name
  create_poll_model_name          = aws_api_gateway_model.create_poll.name
  archive_poll_model_name         = aws_api_gateway_model.archive_poll.name
  update_poll_duration_model_name = aws_api_gateway_model.update_poll_duration.name
  error_model_name                = aws_api_gateway_model.error.name
  parent_id                       = module.rest_api.root_resource_id
  custom_authorizer_id            = module.api_authorizer.id
  single_table_name               = aws_dynamodb_table.single_table.name
  single_table_arn                = aws_dynamodb_table.single_table.arn
  nanoid_alphabet                 = var.nanoid_alphabet
  nanoid_length                   = var.nanoid_length
  lambda_logging_policy_arn       = module.lambda_logging.policy_arn
}

module "vote_queue_microservice" {
  source                    = "./modules/microservices/vote-queue"
  api_role_name             = module.api_gateway_iam.role_name
  api_role_arn              = module.api_gateway_iam.role_arn
  rest_api_id               = module.rest_api.id
  error_model_name          = aws_api_gateway_model.error.name
  poll_resource_id          = module.poll_manager_microservice.poll_resource_id
  custom_authorizer_id      = module.api_authorizer.id
  public_poll_resource_id   = module.poll_manager_microservice.public_poll_resource_id
  lambda_logging_policy_arn = module.lambda_logging.policy_arn
  region                    = local.region
  single_table_name         = aws_dynamodb_table.single_table.name
  single_table_arn          = aws_dynamodb_table.single_table.arn
  event_bus_name            = module.choreography.event_bus_name
  event_bus_arn             = module.choreography.event_bus_arn
}
