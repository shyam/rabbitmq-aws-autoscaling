resource "aws_instance" "bastion-host01-a" {
  ami = "${lookup(var.bastion_instance_ami, var.aws_region)}" 
  instance_type = "${var.bastion_instance_type}"
  key_name = "${aws_key_pair.master_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  subnet_id = "${aws_subnet.bastion-a.id}"
  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
  }
  tags {
    Name = "${var.environment_name}-bastion-host01-a"
    TF-Managed = true
  }
} 