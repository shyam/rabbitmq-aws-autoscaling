resource "aws_key_pair" "master_key" {
  key_name = "${var.master_key_name}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD2jWzSUDNyhGTKijdJ/os76CtllhPVrzxWswfCPFw6dggA3qiFDENFx0kR4BBrUcv1+7s16RA31nHvECckdKYKtx6pNPP0/IYV9KcpmehXVffMN0WjPDHl+Zc0SYsrITfFvkKKC5lEsEZjJ1J/Fbuyw+4VvpRmntLqBS1UF3EOZDMKLYkzjYknJL6gKDo2Y6g+H8t3bHzuosh6+pk0AGUnxLBWJYaYXUqo3++ySZphZTmHFiU/d+zX1H2uZOScqbKapadYqcGcvVMVL/5KqRamke6uDRIJpPL+SqcBc91NSWH5kdcDRTAwjbSMqsaGYDtfHS4M1Z4PXpZODFI2MMFN AWS-SS"
}
