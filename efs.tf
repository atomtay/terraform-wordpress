resource "aws_efs_file_system" "files" {
  encrypted = true
}

resource "aws_security_group" "mount_target_sg" {
  vpc_id      = aws_vpc.main.id
  description = "EFS security group"
}

resource "aws_vpc_security_group_ingress_rule" "mount_target_ingress" {
  security_group_id = aws_security_group.mount_target_sg.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = "10.0.0.0/16"
}

resource "aws_efs_mount_target" "mount_targets" {
  count           = length(aws_subnet.private)
  file_system_id  = aws_efs_file_system.files.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.mount_target_sg.id]
}

resource "aws_efs_access_point" "access_point" {
  file_system_id = aws_efs_file_system.files.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 0777
    }
    path = "/bitnami"
  }
}
