
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Express-ressursen (aws_ecs_express_gateway_service) finnes bare i nyere 6.x-versjoner
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}