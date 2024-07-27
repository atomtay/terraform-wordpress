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

resource "aws_rds_cluster" "default" {

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  availability_zones     = data.aws_availability_zones.available.names
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  port                   = 3306

  database_name      = "wordpress"
  cluster_identifier = "wordpress-db"
  engine             = "aurora-mysql"
  engine_version     = "5.7"
  engine_mode        = "provisioned"
  storage_encrypted  = true

  master_username             = "postgres"
  manage_master_user_password = true

  backup_retention_period = var.db_backup_retention
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = var.skip_final_snapshot
}

resource "aws_rds_cluster_instance" "instances" {
  count              = 2
  identifier         = "wordpress-db-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
}
