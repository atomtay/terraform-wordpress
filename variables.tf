variable "region" {
  type    = string
  default = "us-east-2"
}

variable "db_backup_retention" {
  type = number
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}
