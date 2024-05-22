resource "random_pet" "main" {
  length = 2
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "master" {

}

data "aws_key_pair" "key" {
  key_name = var.key_name
}

resource "aws_eip_association" "master" {
  allocation_id = aws_eip.master.id
  instance_id   = aws_instance.master.id
}

resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = aws_subnet.main.id
  instance_type               = var.node_instance_type
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.key.key_name
  user_data                   = filebase64("./scripts/user-data.sh")

  vpc_security_group_ids = [
    aws_security_group.allow_all_egress.id,
    aws_security_group.ssh.id,
    aws_security_group.allow_apiserver_ingress.id,
    aws_security_group.allow_internal.id
  ]
}

resource "aws_instance" "worker" {
  count                       = var.worker_count
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = aws_subnet.main.id
  instance_type               = var.node_instance_type
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.key.key_name
  user_data                   = filebase64("./scripts/user-data.sh")

  vpc_security_group_ids = [
    aws_security_group.allow_all_egress.id,
    aws_security_group.ssh.id,
    aws_security_group.allow_internal.id,
    aws_security_group.allow_node_port_services.id
  ]
}

resource "aws_security_group" "ssh" {
  name        = "${random_pet.main.id}-master-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow SSH"

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_all_egress" {
  name        = "${random_pet.main.id}-allow-all-egress"
  description = "Allow all egress traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_apiserver_ingress" {
  name        = "${random_pet.main.id}-api-server-ingress"
  description = "Allow ingress traffic to apiserver"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_node_port_services" {
  name        = "${random_pet.main.id}-allow-node-port-services"
  description = "Allow TCP to node port range"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_internal" {
  name        = "${random_pet.main.id}-allow-internal"
  description = "Allow traffic between K8 nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}
