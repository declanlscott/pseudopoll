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

module "apigateway_iam" {
  source = "./modules/api-gateway/iam"
}

module "rest_api" {
  source      = "./modules/api-gateway"
  name        = "pseudopoll-rest-api"
  domain_name = var.domain_name
  zone_id     = aws_route53_zone.zone.zone_id

  redeployment_trigger_hashes = concat([module.poll_manager_microservice.resources_hash])
}

module "api_authorizer" {
  source              = "./modules/api-gateway/authorizer"
  name                = "pseudopoll-authorizer"
  function_name       = "pseudopoll-authorizer"
  rest_api_id         = module.rest_api.id
  archive_source_file = "${path.module}/../backend/lambdas/authorizer/bin/bootstrap"
  archive_output_path = "${path.module}/../backend/lambdas/authorizer/bin/authorizer.zip"
  jwks_uri            = var.jwks_uri
  audience            = var.audience
  token_issuer        = var.token_issuer
}

module "poll_manager_microservice" {
  source               = "./modules/microservices/poll-manager"
  rest_api_id          = module.rest_api.id
  stage_name           = module.rest_api.stage_name
  parent_id            = module.rest_api.root_resource_id
  custom_authorizer_id = module.api_authorizer.id
  nanoid_length        = var.nanoid_length
}
