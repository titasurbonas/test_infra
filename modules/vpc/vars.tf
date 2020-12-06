variable cidr_block {
  type        = string
  description = "CIDR block for vpc"
  validation{
      condition = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", var.cidr_block))
      error_message = "Invalide cdir block."
  }
}
variable ip_subnets_private{
  type  = list(string)
  description = "subnet ips private"
  validation{
      condition = can([ for s in var.ip_subnets_private: regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", s)])
      error_message = "Invalid ip(s) subnets private."
  }
}
variable ip_subnets_public{
  type  = list(string)
  description = "subnet ips private"
  default = []
  validation{
      condition = can([ for s in var.ip_subnets_public: regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", s)])
      error_message = "Invalid ip(s) subnets private."
  }
}
variable availability_zone{
  type = list(string)
  description = "list of availability zones"
}
variable enable_dns_support {
  type        = bool
  default     = false
}

variable enable_dns_hostnames {
  type        = bool
  default     = false
}

variable vpc_name {
  type        = string
  default     = ""
}

variable extra_cdir_block {
  type    = list(string)
  default = []
  description= "list of extra CDIR bloks"
}

variable vpc_tags {
  type = map(string)
  default = {}
  description = "map of tag which will be deployed on all resources"
}

variable enable_dhcp_options{
  type = bool
  default = false
}

variable dhcp_options_domain_name {
  description = "Specifies DNS name for DHCP options set (requires enable_dhcp_options set to true)"
  type        = string
  default     = ""
}

variable dhcp_options_domain_name_servers {
  description = "Specify a list of DNS server addresses for DHCP options set, default to AWS provided (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable dhcp_options_ntp_servers {
  description = "Specify a list of NTP servers for DHCP options set (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = []
}

variable dhcp_options_netbios_name_servers {
  description = "Specify a list of netbios servers for DHCP options set (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = []
}

variable dhcp_options_netbios_node_type {
  description = "Specify netbios node_type for DHCP options set (requires enable_dhcp_options set to true)"
  type        = string
  default     = ""
}

variable enable_private_subnet_internet_gateway{
  type = bool
  default = false

}

variable enable_public_subnet_internet_gateway{
  type = bool
  default = false
}

