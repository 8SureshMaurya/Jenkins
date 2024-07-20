output "vpc_id" {
  value = aws_vpc.ninja_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.ninja_pub_sub[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.ninja_priv_sub[*].id
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "private_instance_id" {
  value = aws_instance.private_instance.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.ninja_igw.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.ninja_nat.id
}

output "public_route_table_id" {
  value = aws_route_table.ninja_route_pub.id
}

output "private_route_table_id" {
  value = aws_route_table.ninja_route_priv.id
}
