output "vpc_id" {
  value = aws_vpc.tf_vpc.id
}

output "public_subnet_ids" {
  value = [aws_subnet.tf_public_a.id, aws_subnet.tf_public_c.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.tf_private_a.id, aws_subnet.tf_private_c.id]
}

output "security_group_alb_id" {
  value = aws_security_group.tf_alb_sg.id
}

output "security_group_ec2_id" {
  value = aws_security_group.tf_ec2_sg.id
}

# 割当済みElastic IPのID
output "eip_allocation_id" {
  value = aws_eip.tf_natgateway_eip.id
}

# NAT GatewayのID
output "nat_gateway_id" {
  value = aws_nat_gateway.tf_natgateway.id
}

# パブリックサブネット(1a)のID
output "subnet_id" {
  value = aws_subnet.tf_public_a.id
}