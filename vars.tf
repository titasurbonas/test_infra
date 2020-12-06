variable aws_region {
  type        = string
  default     = "eu-west-1"
  description = "Region of aws where to deploy resouces"
}
variable account_id {
  type        = string
  default     = "760948252845"
}

variable ip_subnets_private {
  type        = list(string)
  default     = ["10.206.104.192/28"]
  description = "description"
}

variable ip_subnets_public {
  type        = list(string)
  default     = ["10.206.104.208/28"]
  description = "description"
}



