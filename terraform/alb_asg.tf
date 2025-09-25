#############################
# Target Group
#############################
resource "aws_lb_target_group" "tg" {
  name     = "${local.name}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/healthz"
    matcher             = "200"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#############################
# Application Load Balancer
#############################
resource "aws_lb" "alb" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "${local.name}-alb"
  }
}

#############################
# ALB Listener (HTTP :80)
#############################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

#############################
# Launch Template (EC2)
#############################

# Amazon Linux 2 AMI (x86_64)
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${local.name}-lt-"
  image_id      = data.aws_ami.al2.id
  instance_type = var.instance_type

  # attach the EC2 security group
  network_interfaces {
    security_groups = [aws_security_group.ec2.id]
  }

  # Install & start Docker; pull & run the app on port 3000
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail

    yum update -y
    amazon-linux-extras install docker -y || yum install -y docker
    systemctl enable docker
    systemctl start docker

    # pull & run your app container
    docker pull ${var.docker_image}
    docker rm -f app || true
    docker run -d --restart=always --name app -p 3000:3000 ${var.docker_image}
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name}-ec2"
    }
  }
}

#############################
# Auto Scaling Group
#############################
resource "aws_autoscaling_group" "asg" {
  name             = "${local.name}-asg"
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  vpc_zone_identifier = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  target_group_arns         = [aws_lb_target_group.tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  # roll instances automatically when the LT changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-ec2"
    propagate_at_launch = true
  }
}
