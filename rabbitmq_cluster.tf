resource "aws_iam_role" "autoscaling_rabbitmq_role" {
  name = "${var.environment_name}-rabbitm-autoscale"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
  "Effect": "Allow",
  "Principal": {
          "Service": ["ec2.amazonaws.com"]
        },
  "Action": ["sts:AssumeRole"]
     }]
  }
EOF
}

resource "aws_iam_policy" "autoscale_rabbit_policy" {
  name        = "${var.environment_name}-rabbit-autoscale-policy"
  path        = "/"
  description = "rabbitmq_autoscale_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "ec2:DescribeInstances"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "autoscale-rabbit-policy" {
  name = "${var.environment_name}-autoscale-rabbit-attac"
  roles      = ["${aws_iam_role.autoscaling_rabbitmq_role.name}"]
  policy_arn = "${aws_iam_policy.autoscale_rabbit_policy.arn}"
}

resource "aws_iam_instance_profile" "rabbitmq_auto_scale_profile" {
  name = "${var.environment_name}-rabbit-profile"
  role = "${aws_iam_role.autoscaling_rabbitmq_role.name}"
}

resource "aws_autoscaling_group" "rabbitmq-asg" {
  name = "rabbitmq-asg"
  vpc_zone_identifier = ["${aws_subnet.app-a.id}", "${aws_subnet.app-b.id}"]
  max_size = "${var.rabbitmq_asg_max}"
  min_size = "${var.rabbitmq_asg_min}"
  desired_capacity = "${var.rabbitmq_asg_desired}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.rabbitmq-lc.name}"

  load_balancers = [
    "${aws_elb.rabbitmq-elb.name}"
  ]

  termination_policies = [
    "OldestLaunchConfiguration"
  ]

  min_elb_capacity = 3

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "rabbitmq-asg"
    propagate_at_launch = "true"
  }

  tag {
    key = "environment"
    value = "${var.environment_name}"
    propagate_at_launch = "true"
  }

  tag {
    key = "TF-Managed"
    value = true
    propagate_at_launch = "true"
  }
}

data "template_file" "rabbitmq_cloud_init" {
  template = <<EOF
#cloud-config
# Update and upgrade packages
repo_update: true
repo_upgrade: all

# Make sure the following packages are installed.
packages:
 - python-pip
 - ec2-api-tools

# Run the following commands in orders.
runcmd:
 # Setting some defaults
 - echo "*         hard    nofile      500000" >> /etc/security/limits.conf
 - echo "*         soft    nofile      500000" >> /etc/security/limits.conf
 - echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
 - echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
 - echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
 - echo "net.ipv4.tcp_fin_timeout = 1" >> /etc/sysctl.conf
 - sysctl -p /etc/sysctl.conf
 # Using pip install awscli
 - /usr/bin/pip install awscli
 - ln -s /usr/local/bin/aws /usr/bin/aws
 # Setting REGION environment variable
 - export REGION=`/usr/bin/ec2metadata | grep "^availability-zone:" | awk '{print substr($2, 1, length($2)-1)}'`
 - aws configure set default.region $REGION
 - aws configure set default.output text
 # Add RabbitMQ keys and repos to the system
 - wget -O - "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" | sudo apt-key add -
 - echo "deb https://dl.bintray.com/rabbitmq/debian bionic main" | sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list
 # Install RabbitMQ
 - apt-get update && apt-get -y install rabbitmq-server
 # Set the erlang cookie
 - echo "AYCABCDFGRIJKLMNOUPM" > /var/lib/rabbitmq/.erlang.cookie
 # now enable them into the current rabbitmq installation.
 - rabbitmq-plugins enable --offline rabbitmq_management rabbitmq_event_exchange rabbitmq_peer_discovery_aws rabbitmq_peer_discovery_common rabbitmq_federation rabbitmq_federation_management rabbitmq_management rabbitmq_management_agent rabbitmq_mqtt rabbitmq_stomp
 # Setting default configuration in /etc/rabbitmq/rabbitmq.config
 - echo "cluster_formation.peer_discovery_backend = rabbit_peer_discovery_aws" >> /etc/rabbitmq/rabbitmq.conf
 - echo "cluster_formation.aws.region = $REGION" >> /etc/rabbitmq/rabbitmq.conf
 - echo "cluster_formation.aws.use_autoscaling_group = true" >> /etc/rabbitmq/rabbitmq.conf
 - echo "log.file.level = debug" >> /etc/rabbitmq/rabbitmq.conf
 - echo "HOSTNAME=`curl -s 169.254.169.254\/latest\/meta-data\/local-hostname`" >> /etc/rabbitmq/rabbitmq-env.conf
 - echo "RABBITMQ_ERLANG_COOKIE=AYCABCDFGRIJKLMNOUPM" >> /etc/rabbitmq/rabbitmq-env.conf
 - echo "RABBITMQ_USE_LONGNAME=true" >> /etc/rabbitmq/rabbitmq-env.conf
 # Permissions again
 - chown rabbitmq.rabbitmq /etc/rabbitmq/rabbitmq.conf
 # Restart RabbitMQ to load new configuration
 - systemctl restart rabbitmq-server.service
 # List all plugins
 - rabbitmq-plugins list
 # Add a new vhost
 - /usr/sbin/rabbitmqctl add_vhost /main/
 # Add a new admin user
 # Change the value of <some-extra-secure-password>
 - /usr/sbin/rabbitmqctl add_user admin RabbitsGoneMad
 - /usr/sbin/rabbitmqctl set_user_tags admin administrator
 # Setting permissions to the admin user to the two vhosts we have.
 - /usr/sbin/rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
 - /usr/sbin/rabbitmqctl set_permissions -p /main/ admin ".*" ".*" ".*"
 # Set policies
 - /usr/sbin/rabbitmqctl set_policy -p / qml-policy ".*" '{"queue-master-locator":"random"}'
 - /usr/sbin/rabbitmqctl set_policy -p /main/ uae-policy ".*" '{"queue-master-locator":"random", "ha-mode":"all", "ha-sync-mode":"automatic"}'
EOF
}

# Launch Configuration for the cluster instances
resource "aws_launch_configuration" "rabbitmq-lc" {
  name_prefix = "rabbitmq-lc-"
  image_id = "${lookup(var.rabbitmq_instance_ami, var.aws_region)}" 
  instance_type = "${var.rabbitmq_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.rabbitmq_auto_scale_profile.id}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
    delete_on_termination = true
  }

  # Security group
  security_groups = [
    "${aws_security_group.app.id}"
  ]

  user_data = "${data.template_file.rabbitmq_cloud_init.rendered}"
  key_name = "${var.master_key_name}"
}

resource "aws_elb" "rabbitmq-elb" {
  name = "${var.environment_name}-rabbit"
  subnets = ["${aws_subnet.app-a.id}", "${aws_subnet.app-b.id}"]
  security_groups = ["${aws_security_group.app.id}"]
  internal = true

  listener {
    instance_port = 5672
    instance_protocol = "tcp"
    lb_port = 5672
    lb_protocol = "tcp"
  }

  listener {
    instance_port = 15672
    instance_protocol = "http"
    lb_port = 15672
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    target = "HTTP:15672/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "${var.environment_name}-rabbitmq"
    Env = "${var.environment_name}"
    TF-Managed = true
  }
}
