terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.20.1"
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

module "remote_backend" {
  source = "./modules/remote-backend"
}

module "http_api" {
  source = "./modules/api-gateway"
  name   = "pseudopoll-http-api"
}

module "sfn_iam" {
  source = "./modules/sfn-state-machine/iam"
}

module "poll_manager_microservice" {
  source       = "./modules/microservices/poll-manager"
  api_id       = module.http_api.api_id
  sfn_role_arn = module.sfn_iam.iam_for_sfn_arn
}
