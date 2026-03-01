terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


provider "aws" {
  alias  = "dns"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${var.dns_account_id}:role/Route53ChangeRecordsFromWorkload"
  }
}


# Lookup the latest Amazon Linux 2023 AMI (x86_64)
# You can switch to Amazon Linux 2 by adjusting owners/filters if required.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Security group: 443 open to the world, 22 only from your IP
resource "aws_security_group" "web_sg" {
  name        = "${var.name}-sg"
  description = "SG for ${var.name}: 443 open to world, 22 from my IP"
  vpc_id      = var.vpc_id

  # HTTPS from anywhere (IPv4)
  ingress {
    description = "HTTPS from anywhere (IPv4)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "HTTP from anywhere (IPv4)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH only from your IP (expects x.x.x.x/32 in var.my_ip_cidr)
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }
}

# User data to install Docker and run OWASP Juice Shop
# Note: AL2023 uses dnf; yum alias exists, but we keep commands as provided.
locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl enable docker
    systemctl start docker
    docker pull bkimminich/juice-shop
    yum install -y nginx
    yum install -y certbot python-certbot-nginx lsof
  EOF
}
# Manually run, can also bake into an AMI or work into user data script
# sudo certbot --nginx \
#     -d TODO:your_domain \
#     --non-interactive \
#     --agree-tos \
#     --email admin@test.com
# docker run -d -p 3000:3000 --name juice-shop bkimminich/juice-shop

resource "aws_network_interface" "app_eni" {
  subnet_id       = var.public_subnet_id
  security_groups = [aws_security_group.web_sg.id]
  tags = { Name = "${var.name}-eni" }
}


# EC2 instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  # subnet_id              = var.public_subnet_id
  # vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  # associate_public_ip_address = false

  user_data = local.user_data

  primary_network_interface {
    network_interface_id = aws_network_interface.app_eni.id
    # device_index         = 0
  }



  tags = {
    Name = var.name
  }

  metadata_options {
    http_tokens = "required"
  }

  # Root volume options (optional tweak)
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }
}


resource "aws_eip" "app_eip" {
  domain = "vpc"
  tags   = { Name = "${var.name}-eip" }
}

# Associate the EIP to the instance (by instance ID)
resource "aws_eip_association" "app_eip_assoc" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app_eip.id
}

resource "aws_route53_record" "app_a" {
  provider = aws.dns

  zone_id = var.dns_hosted_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_eip.app_eip.public_ip]

}


output "instance_public_ip" {
  value = aws_eip.app_eip.public_ip
}

output "security_group_id" {
  value = aws_security_group.web_sg.id
}

# DNS TXT record for AWS Security Agent verification
# resource "aws_route53_record" "security_agent_verification" {
#   zone_id = var.dns_hosted_zone_id

#   name    = "_aws_securityagent-challenge.heartlandbusiness.click"
#   type    = "TXT"
#   ttl     = 60
#   records = [
#     "\"aws-securityagent-domain-verification=O15sY_-a4UbIrtyh335s3w\""
#   ]

#   allow_overwrite = true
# }
