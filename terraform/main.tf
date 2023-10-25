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

module "sfn_iam" {
  source = "./modules/sfn-state-machine/iam"
}

module "rest_api" {
  source = "./modules/api-gateway"
  name   = "pseudopoll-rest-api"
}

module "lambda_iam" {
  source = "./modules/lambda/iam"
}

module "api_authorizer" {
  source              = "./modules/api-gateway/authorizer"
  name                = "pseudopoll-authorizer"
  function_name       = "pseudopoll-authorizer"
  rest_api_id         = module.rest_api.id
  lambda_role_arn     = module.lambda_iam.role_arn
  archive_source_file = "${path.module}/../backend/lambdas/authorizer/bin/bootstrap"
  archive_output_path = "${path.module}/../backend/lambdas/authorizer/bin/authorizer.zip"
  jwks_uri            = var.jwks_uri
  audience            = var.audience
  token_issuer        = var.token_issuer
}

module "poll_manager_microservice" {
  source               = "./modules/microservices/poll-manager"
  rest_api_id          = module.rest_api.id
  parent_id            = module.rest_api.root_resource_id
  sfn_role_arn         = module.sfn_iam.iam_for_sfn_arn
  custom_authorizer_id = module.api_authorizer.id
}
