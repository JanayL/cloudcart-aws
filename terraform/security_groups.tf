# ALB SG: allow HTTP from anywhere
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${local.name}-alb-sg" }
}

# EC2 SG: allow 3000 from ALB only
resource "aws_security_group" "ec2" {
  name        = "${local.name}-ec2-sg"
  description = "App instances"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port                = 3000
    to_port                  = 3000
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb.id]
    description              = "From ALB"
  }

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${local.name}-ec2-sg" }
}
