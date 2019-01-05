### RabbitMQ on AWS

#### Problem Statement:

- To run RabbitMQ on a clustered mode. ( Use RabbitMQ 3.7's peering discovery features ).
- Self healing cluser.
- Production ready setup.

#### Strategy:

- AWS VPC based environment. Segmented subnets for running along with application and not accessible from outside.
- RabbitMQ 3.7 with peering discovery plugin configured run to find the peers launched under Auto Scaling Groups.
- RabbitMQ running on Ubuntu 18.04 under an AutoScalingGroup (ASG). Cloud-Init scripts to configure RabbitMQ instance.
- RabbitMQ to run on application subnet ( internal ) and access exposed with an internal loadbalancer.

#### VPC/Network Architecture (highlevel):

- 2 Public subnets: Edge and Bastion. Edge allows port 80, 443 access. Also used by NAT-GW. Bastion allows port 22 access. Whitelisted access to certain CIDRs of our choice.
- 1 Private subnet: Application. Allows complete access to self. Restricted access from Edge and Bastion.
.. additional subnets for database and others can be added as required by Application acchitecture. 

#### Running:

- Export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
- Update the SSH public key in `security_key.tf`. This is a part of the key pair used when provisioning instances.
- Run `terraform init`
- Run `terraform apply`

#### Areas of improvement:

- Cloud-Init sysprep activity to use ansible scripts rather than shell commands.
- Using NLB (Network Load Balancer) to reduce latency.
- Migrate to separate NAT-GW per availability zone for HA on NAT-GW.
- Modularize Terraform and version control the modules.
- Setup Terraform state locking under S3/DynamoDB.

