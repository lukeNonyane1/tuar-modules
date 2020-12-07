terraform {
  backend "s3" {
      bucket = "${var.db_remote_state_bucket}"
      key = "${var.db_remote_state_key}"
      region = "us-east-1"
      encrypt = true
  }
}

data "aws_availability_zones" "all" {
  all_availability_zones = true
}

/* data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars = {
    server_port = "${var.server_port}"
    # db_address = "${data.terraform_remote_state.db.outputs.address}"
    # db_port = "${data.terraform_remote_state.db.outputs.port}"
  }
} */

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "${var.db_remote_state_bucket}"
    key = "${var.db_remote_state_key}"
    region = "us-east-1"
  }
}

resource "aws_launch_configuration" "instance" {
  image_id = "ami-0885b1f6bd170450c"
  instance_type = "t2.micro"
  security_groups = [ "${aws_security_group.instance.id}" ]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "instance" {
  launch_configuration = "${aws_launch_configuration.instance.id}"
  availability_zones = [ "us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f" ]

  load_balancers = [ "${aws_elb.instance.name}" ]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "webservers-prod"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "webservers-prod"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_internet_traffic" {
  type = "ingress"
  security_group_id = "${aws_security_group.instance.id}"

  from_port = "${var.server_port}"
  to_port = "${var.server_port}"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_elb" "instance" {
  name = "webservers-prod-instance"
  availability_zones = [ "us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f" ] 
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "webservers-prod-elb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type = "egress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}





