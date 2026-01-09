locals {
  ips = ["10.0.0.0/16"]
}

# 1. VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "network-firewall-vpc"
  cidr = "10.0.0.0/16"

  azs        = ["us-east-1a"]
  create_igw = true

  public_subnets  = ["10.0.4.0/28"]
  private_subnets = ["10.0.2.0/24"]

  enable_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
  }
}

# 2. Rule Groups
resource "aws_networkfirewall_rule_group" "allow-vpc-egress" {
  capacity    = 50
  description = "Permits all traffic from source VPC"
  name        = "egress"
  type        = "STATEFUL"
  rule_group {
    rules_source {
      dynamic "stateful_rule" {
        for_each = local.ips
        content {
          action = "PASS"
          header {
            destination      = "ANY"
            destination_port = "ANY"
            protocol         = "IP"
            direction        = "ANY"
            source_port      = "ANY"
            source           = stateful_rule.value
          }
          rule_option {
            keyword  = "sid"
            settings = ["1"]
          }
        }
      }
    }
  }
}

# 3
resource "aws_networkfirewall_rule_group" "allow-vpc-ingress" {
  capacity    = 50
  description = "Permits all traffic from source VPC"
  name        = "ingress"
  type        = "STATEFUL"
  rule_group {
    rules_source {
      dynamic "stateful_rule" {
        for_each = local.ips
        content {
          action = "PASS"
          header {
            destination      = stateful_rule.value
            destination_port = "ANY"
            protocol         = "IP"
            direction        = "ANY"
            source_port      = "ANY"
            source           = "ANY"
          }
          rule_option {
            keyword  = "sid"
            settings = ["1"]
          }
        }
      }
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "this" {
  name        = "example"
  description = "Sample firewall policy"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow-vpc-egress.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow-vpc-ingress.arn
    }
  }
}

# Takes 5 minutes to create
resource "aws_networkfirewall_firewall" "example" {
  name                   = "example"
  description            = "test firewall"
  firewall_policy_arn    = aws_networkfirewall_firewall_policy.this.arn
  vpc_id                 = module.vpc.vpc_id
  enabled_analysis_types = ["TLS_SNI", "HTTP_HOST"]
  subnet_mapping {
    subnet_id = module.vpc.private_subnets[0]
  }

  timeouts {
    create = "40m"
    update = "50m"
    delete = "1h"
  }
}

// Add a route table for IGW
resource "aws_route_table" "example" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block      = "10.0.2.0/24"
    vpc_endpoint_id = one(one(aws_networkfirewall_firewall.example.firewall_status).sync_states).attachment[0].endpoint_id
  }
  tags = {
    Name = "IGW-route-table"
  }
}

resource "aws_route_table_association" "igw" {
  gateway_id     = module.vpc.igw_id
  route_table_id = aws_route_table.example.id
}

resource "aws_route" "private" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = one(one(aws_networkfirewall_firewall.example.firewall_status).sync_states).attachment[0].endpoint_id
}

output "firewall_arn" {
  value = one(one(aws_networkfirewall_firewall.example.firewall_status).sync_states).attachment[0].endpoint_id
}

resource "aws_key_pair" "this" {
  key_name   = "aws_example"
  public_key = var.public_ssh_key_material
}

// Create public EC2 for SSH access
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "public-ec2"

  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.this.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  security_group_ingress_rules = {
    apartment = {
      cidr_ipv4   = var.cidr
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      description = "SSH from office IP"
    }
  }
}

module "private_ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "private-ec2"

  instance_type = "t3.micro"
  key_name      = aws_key_pair.this.key_name
  subnet_id     = module.vpc.private_subnets[0]
  security_group_ingress_rules = {
    internal = {
      cidr_ipv4   = "10.0.0.0/16"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      description = "SSH the VPC"
    }
  }
}
