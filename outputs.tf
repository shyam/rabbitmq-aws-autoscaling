output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "eip1_ip" {
  value = "${aws_eip.eip1.public_ip}"
}

# output "eip2_ip" {
#   value = "${aws_eip.eip2.public_ip}"
# }

output "bastion-host01-a_ip" {
  value = "${aws_instance.bastion-host01-a.public_ip}"
}

output "rabbitmq_launch_configuration" {
  value = "${aws_launch_configuration.rabbitmq-lc.id}"
}

output "rabbitmq_asg_name" {
  value = "${aws_autoscaling_group.rabbitmq-asg.id}"
}

output "rabbitmq_elb_name" {
  value = "${aws_elb.rabbitmq-elb.dns_name}"
}
