terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.58.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "MyVPC" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "MyVPC"
  }
}

# Create public subnets
resource "aws_subnet" "public_1" {
  vpc_id                = aws_vpc.MyVPC.id
  cidr_block            = var.public_subnet_cidrs[0]
  availability_zone     = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                = aws_vpc.MyVPC.id
  cidr_block            = var.public_subnet_cidrs[1]
  availability_zone     = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Create private subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.MyVPC.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.MyVPC.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = var.availability_zones[1]
  tags = {
    Name = "private-subnet-2"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.MyVPC.id
  tags = {
    Name = "main-igw"
  }
}

# NAT Gateway
resource "aws_eip" "NAT" {
  depends_on = [aws_internet_gateway.main_igw]
}

resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.NAT.id
  subnet_id     = aws_subnet.public_1.id
  tags = {
    Name = "main-nat-01"
  }
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.MyVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Create a private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.MyVPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }
  tags = {
    Name = "private-route-table"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

/* Bastion Host SG------------------------------------*/

# Security Group for Bastion Host
resource "aws_security_group" "Public_SG" {
  name        = "public-sg-terraform"
  description = "security group for public instances"
  vpc_id      = aws_vpc.MyVPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "Allow 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public_SG"
  }
}

# Bastion Host (public instance)
resource "aws_instance" "bastion" {
  ami                     = var.ami_id
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.Public_SG.id]
  key_name                = var.key_name
  subnet_id               = aws_subnet.public_1.id

  tags = {
    Name = "ninja-bastion-host"
  }
}

/* Private Instance SG----------------------------------*/
# Security Group for Private Instances
resource "aws_security_group" "Private_SG" {
  name        = "private-sg-terraform"
  description = "security group for private instances"
  vpc_id      = aws_vpc.MyVPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "Allow"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Private_SG"
  }
}

# Jenkins Server (private instance)
resource "aws_instance" "Jenkins_server" {
  ami                     = var.ami_id
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.Private_SG.id]
  key_name                = var.key_name
  subnet_id               = aws_subnet.private_1.id
  user_data               = file(var.jenkins_user_data)
  tags = {
    Name = "Jenkins_server"
  } 
}


/* Load Balancer Target Group ----------------------------------*/
resource "aws_lb_target_group" "jenkins_tg" {
  name     = "jenkins-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.MyVPC.id

  health_check {
    path                = "/login"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "jenkins-tg"
  }
}

/* Register Jenkins server to Target Group --------------------*/
resource "aws_lb_target_group_attachment" "jenkins_attachment" {
  target_group_arn = aws_lb_target_group.jenkins_tg.arn
  target_id        = aws_instance.Jenkins_server.id
  port             = 8080
}

/* Create Load Balancer ----------------------------------------*/
resource "aws_lb" "jenkins_lb" {
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Public_SG.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "jenkins-lb"
  }
}

/* Listener for Load Balancer ----------------------------------*/
resource "aws_lb_listener" "jenkins_listener" {
  load_balancer_arn = aws_lb.jenkins_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}

/*AUTOSCALLING GROUP ----------------------------------*/

# Auto Scaling Group
resource "aws_autoscaling_group" "jenkins_asg" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns    = [aws_lb_target_group.jenkins_tg.arn]
  launch_template {
    id      = aws_launch_template.jenkins_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "jenkins-asg"
    propagate_at_launch = true
  }
}

# Launch Template
resource "aws_launch_template" "jenkins_launch_template" {
  name_prefix   = "jenkins-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.Private_SG.id]
  }

  user_data = filebase64("install_jenkins.sh")

  tags = {
    Name = "jenkins-launch-template"
  }
}

# Scaling Policy based on CPU Utilization
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.jenkins_asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.jenkins_asg.name
}

# CloudWatch Alarm for Scale Up
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.scale_up_threshold
  alarm_description   = "This metric monitors CPU utilization for Auto Scaling"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jenkins_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
}

# CloudWatch Alarm for Scale Down
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale-down-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.scale_down_threshold
  alarm_description   = "This metric monitors CPU utilization for Auto Scaling"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jenkins_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
}

/*Ansible-----------------------------*/

# Generate the Ansible inventory file
data "template_file" "ansible_inventory" {
  template = file("${path.module}/inventory.tpl")

  vars = {
    bastion_public_ip = aws_instance.bastion.public_ip
    jenkins_private_ip = aws_instance.Jenkins_server.private_ip
  }
}

resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "${path.module}/inventory"
}



