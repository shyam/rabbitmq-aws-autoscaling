# bastion security group
resource "aws_security_group" "bastion" {
  name = "${var.environment_name}-bastion"
  description = "bastion security group"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${compact(var.bastion_cidr)}"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${compact(var.bastion_cidr)}"]
  }

  tags {
    Name = "bastion security group for ${var.environment_name}"
    TF-Managed = true
  }
}

# edge security group
resource "aws_security_group" "edge" {
  name = "${var.environment_name}-edge"
  description = "edge security group"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    protocol = "icmp"
    from_port = 30 # traceroute
    to_port = 0
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    protocol = "icmp"
    from_port = 8 # echo-reply
    to_port = 0
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
 
  tags {
    Name = "edge security group for ${var.environment_name}"
    TF-Managed = true
  }
}

# appserver security group
resource "aws_security_group" "app" {
  name = "${var.environment_name}-app"
  description = "appserver security group"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.edge.id}", "${aws_security_group.bastion.id}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.edge.id}", "${aws_security_group.bastion.id}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  ingress {
    protocol = "icmp"
    from_port = 30 # traceroute
    to_port = 0
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    protocol = "icmp"
    from_port = 8 # echo-reply
    to_port = 0
    security_groups = ["${aws_security_group.bastion.id}"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags {
    Name = "appserver security group for ${var.environment_name}"
    TF-Managed = true
  }
}
