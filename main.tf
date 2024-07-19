provider "aws" {
  region = var.region
}

resource "aws_vpc" "ninja_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "ninja-vpc-01"
  }
}

resource "aws_subnet" "ninja_pub_sub" {
  count             = 2
  vpc_id            = aws_vpc.ninja_vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(["ap-southeast-2a", "ap-southeast-2b"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "ninja-pub-sub-${count.index + 1}"
  }
}

resource "aws_subnet" "ninja_priv_sub" {
  count             = 2
  vpc_id            = aws_vpc.ninja_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(["ap-southeast-2a", "ap-southeast-2b"], count.index)
  tags = {
    Name = "ninja-priv-sub-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "ninja_igw" {
  vpc_id = aws_vpc.ninja_vpc.id
  tags = {
    Name = "ninja-igw-01"
  }
}

resource "aws_eip" "ninja_eip" {
  depends_on = [aws_internet_gateway.ninja_igw]
}

resource "aws_nat_gateway" "ninja_nat" {
  allocation_id = aws_eip.ninja_eip.id
  subnet_id     = aws_subnet.ninja_pub_sub[0].id
  tags = {
    Name = "ninja-nat-01"
  }
}

resource "aws_route_table" "ninja_route_pub" {
  vpc_id = aws_vpc.ninja_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ninja_igw.id
  }
  tags = {
    Name = "ninja-route-pub-01"
  }
}

resource "aws_route_table_association" "pub_association" {
  count          = 2
  subnet_id      = aws_subnet.ninja_pub_sub[count.index].id
  route_table_id = aws_route_table.ninja_route_pub.id
}

resource "aws_route_table" "ninja_route_priv" {
  vpc_id = aws_vpc.ninja_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ninja_nat.id
  }
  tags = {
    Name = "ninja-route-priv-01"
  }
}

resource "aws_route_table_association" "priv_association" {
  count          = 2
  subnet_id      = aws_subnet.ninja_priv_sub[count.index].id
  route_table_id = aws_route_table.ninja_route_priv.id
}

resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.ninja_pub_sub[0].id
  key_name      = var.key_name
  tags = {
    Name = "ninja-bastion-host"
  }
}

resource "aws_instance" "jenkins_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.ninja_priv_sub[0].id
  key_name      = var.key_name
  user_data     = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
                sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
                sudo yum install jenkins -y
                sudo systemctl start jenkins
                sudo systemctl enable jenkins
                EOF
  tags = {
    Name = "ninja-jenkins-server"
  }
}

resource "aws_lb" "ninja_alb" {
  name               = "ninja-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.ninja_pub_sub[*].id
  tags = {
    Name = "ninja-alb"
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.ninja_vpc.id

ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}


resource "aws_lb_target_group" "ninja_tg" {
  name     = "ninja-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.ninja_vpc.id
  health_check {
    enabled             = true
    interval            = 30
    path                = "/login"
    port                = "8080"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
  tags = {
    Name = "ninja-tg"
  }
}

resource "aws_lb_listener" "ninja_listener" {
  load_balancer_arn = aws_lb.ninja_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ninja_tg.arn
  }
}

resource "aws_autoscaling_group" "ninja_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = aws_subnet.ninja_priv_sub[*].id
  target_group_arns    = [aws_lb_target_group.ninja_tg.arn]
  health_check_type    = "EC2"
  health_check_grace_period = 300
  launch_configuration = aws_launch_configuration.ninja_launch_config.id

  tag {
    key                 = "Name"
    value               = "ninja-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "ninja_launch_config" {
  image_id          = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  security_groups   = [aws_security_group.jenkins_sg.id]
  user_data         = <<-EOF
                      #!/bin/bash
                      sudo yum update -y
                      sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
                      sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
                      sudo yum install jenkins -y
                      sudo systemctl start jenkins
                      sudo systemctl enable jenkins
                      EOF
}

resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.ninja_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

