output "elb_dns" {
  value = "${aws_elb.instance.dns_name}"
}

