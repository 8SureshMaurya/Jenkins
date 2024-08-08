output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.MyVPC.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "bastion_host_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion.public_ip
}

output "jenkins_lb_dns" {
  description = "DNS name of the Jenkins load balancer"
  value       = aws_lb.jenkins_lb.dns_name
}
/*
output "Autoscaling_group_name" {
  description = "The name of the Auto Scaling group"
  value       = aws_autoscaling_group.jenkins_asg.name
}
*/
