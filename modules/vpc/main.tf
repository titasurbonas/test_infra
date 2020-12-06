locals{
  vpc_id = element(
    concat(
      aws_vpc_ipv4_cidr_block_association.cidr_block_association.*.vpc_id,
      aws_vpc.vpc.*.id,
      [""],
    ),
    0,
  )
}
resource aws_vpc vpc {
    cidr_block           = var.cidr_block 
    enable_dns_support   = var.enable_dns_support 
    enable_dns_hostnames = var.enable_dns_hostnames         
    tags=merge(
        {
        Name = var.vpc_name
        },
        var.vpc_tags
    )
}

resource aws_vpc_ipv4_cidr_block_association cidr_block_association {
    count = length(var.extra_cdir_block)
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.extra_cdir_block, count.index)
} 

resource aws_internet_gateway internet_gateway {
  count = var.enable_private_subnet_internet_gateway || var.enable_public_subnet_internet_gateway  ? 1 : 0
  vpc_id = local.vpc_id

  tags = {
    Name = "main"
  }
}
#################
# Private subnet#
#################



resource aws_route route_private {
  count = var.enable_private_subnet_internet_gateway ? length(var.ip_subnets_private) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway[0].id

  timeouts {
    create = "5m"
  }
}

resource aws_route_table private {
  count = length(var.ip_subnets_private)

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-Private-%s",
        var.vpc_name,
        element(var.availability_zone, count.index),
      )
    },
    var.vpc_tags,
  )

  lifecycle {
# most likly private subne is used with vpn connection which is fragile and 
# recreation is disaster we ignore changes on vpn connection
    ignore_changes = [propagating_vgws]
  }
}

resource aws_route_table_association private {
    count = length(var.ip_subnets_private) > 0 ? length(var.ip_subnets_private) : 0

    subnet_id = element(aws_subnet.private.*.id, count.index)
    route_table_id = element( aws_route_table.private.*.id,count.index)
}

resource aws_subnet private {
  count = length(var.ip_subnets_private) 

  vpc_id               = local.vpc_id
  cidr_block           = var.ip_subnets_private[count.index]
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.availability_zone, count.index))) > 0 ? element(var.availability_zone, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.availability_zone, count.index))) == 0 ? element(var.availability_zone, count.index) : null
 
  tags = merge(
    {
      "Name" = format(
        "%s-Private-%s",
        var.vpc_name,
        element(var.availability_zone, count.index),
      )
    },
    var.vpc_tags
  )
}

#################
# Public subnet #
#################

resource aws_route route_public {
  count = var.enable_public_subnet_internet_gateway ? length(var.ip_subnets_public) : 0

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway[0].id

  timeouts {
    create = "5m"
  }
}

resource aws_route_table public {
  count = length(var.ip_subnets_public)

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-public-%s",
        var.vpc_name,
        element(var.availability_zone, count.index),
      )
    },
    var.vpc_tags,
  )
}

resource aws_route_table_association public {
    count = length(var.ip_subnets_public)

    subnet_id = element(aws_subnet.public.*.id, count.index)
    route_table_id = element( aws_route_table.public.*.id,count.index)
}

resource aws_subnet public {
  count = length(var.ip_subnets_public) 

  vpc_id               = local.vpc_id
  cidr_block           = var.ip_subnets_public[count.index]
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.availability_zone, count.index))) > 0 ? element(var.availability_zone, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.availability_zone, count.index))) == 0 ? element(var.availability_zone, count.index) : null
 
  tags = merge(
    {
      "Name" = format(
        "%s-Public-%s",
        var.vpc_name,
        element(var.availability_zone, count.index),
      )
    },
    var.vpc_tags
  )
}
resource aws_vpc_dhcp_options vpc_dhcp_options{
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    {
      "Name" = format("%s", var.vpc_name)
    },
    var.vpc_tags,
  )
}

resource aws_vpc_dhcp_options_association vpc_dhcp_options_association {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.vpc_dhcp_options[0].id
}
