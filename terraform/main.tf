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
  resources_hash = sha1(jsonencode([
    aws_api_gateway_model.poll,
    aws_api_gateway_model.create_poll,
    aws_api_gateway_model.archive_poll,
    aws_api_gateway_model.vote,
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

  schema = templatefile("./modules/templates/models/create-poll.json", {})
}

resource "aws_api_gateway_model" "archive_poll" {
  rest_api_id  = module.rest_api.id
  name         = "ArchivePoll"
  description  = "Archive poll schema"
  content_type = "application/json"

  schema = templatefile("./modules/templates/models/archive-poll.json", {})
}

resource "aws_api_gateway_model" "vote" {
  rest_api_id  = module.rest_api.id
  name         = "Vote"
  description  = "Vote schema"
  content_type = "application/json"

  schema = templatefile(
    "./modules/templates/models/vote.json",
    { nanoIdLength = var.nanoid_length }
  )
}

resource "aws_api_gateway_model" "error" {
  rest_api_id  = module.rest_api.id
  name         = "Error"
  description  = "Error schema"
  content_type = "application/json"

  schema = templatefile("./modules/templates/models/error.json", {})
}

module "poll_manager_microservice" {
  source                    = "./modules/microservices/poll-manager"
  rest_api_id               = module.rest_api.id
  rest_api_execution_arn    = module.rest_api.execution_arn
  stage_name                = module.rest_api.stage_name
  poll_model_name           = aws_api_gateway_model.poll.name
  create_poll_model_name    = aws_api_gateway_model.create_poll.name
  archive_poll_model_name   = aws_api_gateway_model.archive_poll.name
  error_model_name          = aws_api_gateway_model.error.name
  parent_id                 = module.rest_api.root_resource_id
  custom_authorizer_id      = module.api_authorizer.id
  nanoid_alphabet           = var.nanoid_alphabet
  nanoid_length             = var.nanoid_length
  lambda_logging_policy_arn = module.lambda_logging.policy_arn
}

module "vote_queue_microservice" {
  source                    = "./modules/microservices/vote-queue"
  api_role_name             = module.api_gateway_iam.role_name
  api_role_arn              = module.api_gateway_iam.role_arn
  rest_api_id               = module.rest_api.id
  vote_model_name           = aws_api_gateway_model.vote.name
  error_model_name          = aws_api_gateway_model.error.name
  nanoid_length             = var.nanoid_length
  poll_resource_id          = module.poll_manager_microservice.poll_resource_id
  custom_authorizer_id      = module.api_authorizer.id
  public_poll_resource_id   = module.poll_manager_microservice.public_poll_resource_id
  lambda_logging_policy_arn = module.lambda_logging.policy_arn
  region                    = "us-east-2"
}
