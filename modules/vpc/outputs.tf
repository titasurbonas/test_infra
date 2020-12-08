output vpc_id {
  value       = aws_vpc.vpc.id

}
output public_subnet_id {
  value       = aws_subnet.public.*.id
}
output private_subnet_id {
  value       = aws_subnet.private.*.id
}

output route_table_public {
  value       =  aws_route_table.public.*.id

}

output route_table_private {
  value       = aws_route_table.private.*.id

}
