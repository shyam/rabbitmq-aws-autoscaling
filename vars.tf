variable "environment_name" {
  default = "production"
}

variable "aws_region" {
  default = "eu-central-1"
}

variable "vpc_name" {
  default = "prod-01"
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "app-a_cidr" {
  default = "10.1.0.0/18"
}

variable "app-b_cidr" {
  default = "10.1.64.0/18"
}

variable "edge-a_cidr" {
  default = "10.1.152.0/22"
}

variable "edge-b_cidr" {
  default = "10.1.156.0/22"
}

variable "bastion-a_cidr" {
  default = "10.1.160.0/24"
}

variable "bastion-b_cidr" {
  default = "10.1.161.0/24"
}

variable "default_gw_cidr" {
  description = "Default CIDR for internet access"
  default = "0.0.0.0/0"
}

variable "bastion_cidr" {
  type = "list"
  default = ["0.0.0.0/0"]
}

variable "master_key_name" {
  default = "AWS-SS"
}

variable "bastion_instance_type" {
  description = "instance type used for bastion"
  default = "t2.nano"
}

variable "bastion_instance_ami" {
  description = "AMI ID for this region"
  type = "map"
  default = {
    "us-east-1" = "ami-05aa248bfb1c99d0f",
    "eu-central-1" = "ami-0390c2c0c27b5d6b8"
  }
}

variable "rabbitmq_instance_type" {
  default = "t2.medium"
  description = "AWS instance type for running rabbitmq"
}

variable "rabbitmq_instance_ami" {
  type = "map"
  default = {
    "us-east-1" = "ami-05aa248bfb1c99d0f",
    "eu-central-1" = "ami-0390c2c0c27b5d6b8"
  }
}

variable "rabbitmq_asg_min" {
  description = "Min numbers of servers in ASG"
  default = "3"
}

variable "rabbitmq_asg_max" {
  description = "Max numbers of servers in ASG"
  default = "7"
}

variable "rabbitmq_asg_desired" {
  description = "Desired numbers of servers in ASG"
  default = "3"
}
