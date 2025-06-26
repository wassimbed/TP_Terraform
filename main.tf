
provider "aws" {
  region = var.region
}

resource "aws_vpc" "wbe_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "wbe_subnet_a" {
  vpc_id                  = aws_vpc.wbe_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az1
  map_public_ip_on_launch = true
}

resource "aws_subnet" "wbe_subnet_b" {
  vpc_id                  = aws_vpc.wbe_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.az2
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "wbe_igw" {
  vpc_id = aws_vpc.wbe_vpc.id
}

resource "aws_route_table" "wbe_rt" {
  vpc_id = aws_vpc.wbe_vpc.id
}

resource "aws_route" "wbe_default" {
  route_table_id         = aws_route_table.wbe_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wbe_igw.id
}

resource "aws_route_table_association" "wbe_rta_a" {
  subnet_id      = aws_subnet.wbe_subnet_a.id
  route_table_id = aws_route_table.wbe_rt.id
}

resource "aws_route_table_association" "wbe_rta_b" {
  subnet_id      = aws_subnet.wbe_subnet_b.id
  route_table_id = aws_route_table.wbe_rt.id
}

resource "aws_security_group" "wbe_sg" {
  name        = "wbe-sg"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.wbe_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "wbe_alb" {
  name               = "wbe-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wbe_sg.id]
  subnets            = [aws_subnet.wbe_subnet_a.id, aws_subnet.wbe_subnet_b.id]
}

resource "aws_lb_target_group" "wbe_tg" {
  name     = "wbe-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wbe_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "wbe_listener" {
  load_balancer_arn = aws_lb.wbe_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wbe_tg.arn
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "wbe_lt" {
  name_prefix   = "wbe-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wbe_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "<h1>Instance ID: $INSTANCE_ID</h1>" > /var/www/html/index.html
EOF
  )
}

resource "aws_autoscaling_group" "wbe_asg" {
  desired_capacity     = 3
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.wbe_subnet_a.id, aws_subnet.wbe_subnet_b.id]
  target_group_arns    = [aws_lb_target_group.wbe_tg.arn]
  health_check_type    = "EC2"

  launch_template {
    id      = aws_launch_template.wbe_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "wbe_Instance"
    propagate_at_launch = true
  }
}
