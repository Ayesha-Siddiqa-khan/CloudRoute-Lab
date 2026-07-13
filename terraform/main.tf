terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project           = var.project_name
      Environment       = var.environment
      ManagedBy         = "TerraPilot"
      TerraPilotProject = var.project_name
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  project_slug     = trim(replace(lower(var.project_name), "/[^0-9a-z-]/", "-"), "-")
  environment_slug = trim(replace(lower(var.environment), "/[^0-9a-z-]/", "-"), "-")
  resource_prefix  = (local.project_slug == local.environment_slug || endswith(local.project_slug, "-${local.environment_slug}")) ? local.project_slug : "${local.project_slug}-${local.environment_slug}"
}
