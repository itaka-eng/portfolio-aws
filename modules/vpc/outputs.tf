output "vpc_id" {
  value = aws_vpc.tf_vpc.id
}

output "public_subnet_ids" {
  value = [aws_subnet.tf_public_a.id, aws_subnet.tf_public_c.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.tf_private_a.id, aws_subnet.tf_private_c.id]
}
