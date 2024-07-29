resource "aws_db_subnet_group" "db_subnets" {
  name       = "wordpress_subnets"
  subnet_ids = aws_subnet.public.*.id
}

resource "aws_security_group" "db_sg" {
  vpc_id      = aws_vpc.main.id
  description = "RDS security group"
}

resource "aws_vpc_security_group_ingress_rule" "db_ingress" {
  security_group_id = aws_security_group.db_sg.id
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = "10.0.0.0/16"
}

resource "aws_db_instance" "mariadb" {
  allocated_storage           = 10
  auto_minor_version_upgrade  = true
  db_name                     = "wordpress"
  db_subnet_group_name        = aws_db_subnet_group.db_subnets.name
  engine                      = "mariadb"
  engine_version              = "10.11"
  instance_class              = var.db_instance_class
  username                    = "admin"
  manage_master_user_password = true
  port                        = 3306
  skip_final_snapshot         = true
  storage_encrypted           = true
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
}
