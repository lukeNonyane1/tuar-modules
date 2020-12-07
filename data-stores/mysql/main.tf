terraform {
  backend "s3" {
      bucket = "${var.db_remote_state_bucket}"
      key = "${var.db_remote_state_key}"
      region = "us-east-1"
      encrypt = true
  }
}

resource "aws_db_instance" "db" {
    engine = "mysql"
    allocated_storage = 10
    instance_class = "${var.db_instance_class}"
    name = "proddb"
    username = "admin"
    password = "${var.db_password}"
    skip_final_snapshot = true
}