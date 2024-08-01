resource "aws_security_group" "alb_sg" {
  vpc_id      = aws_vpc.main.id
  description = "ALB security group"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress" {
  security_group_id = aws_security_group.db_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "wordpress_lb" {
  name            = "wordpress-lb"
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = aws_subnet.public.*.id
}

resource "aws_lb_target_group" "wordpress_tg" {
  name        = "wordpress-tg"
  target_type = "ip"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_listener" "wordpress_listener" {
  load_balancer_arn = aws_lb.wordpress_lb.arn
  protocol          = "HTTP"
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
}
