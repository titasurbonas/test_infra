terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.35.0"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}
