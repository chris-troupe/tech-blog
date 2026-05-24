terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "6.41.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  use_custom_endpoint_domain = (
    var.application_domain != null &&
    var.domain_certificate_arn != null &&
    var.endpoint_domain_prefix != null
  )
}

resource "aws_verifiedaccess_instance" "rds" {
  description = var.instance_description
  tags = {
    Name = var.verified_access_instance_name
  }
}

resource "aws_verifiedaccess_trust_provider" "user" {
  description              = var.trust_provider_description
  policy_reference_name    = var.trust_provider_policy_reference_name
  trust_provider_type      = "user"
  user_trust_provider_type = "iam-identity-center"
  tags = {
    Name = var.verified_access_trust_provider_name
  }
}

resource "aws_verifiedaccess_instance_trust_provider_attachment" "user" {
  verifiedaccess_instance_id       = aws_verifiedaccess_instance.rds.id
  verifiedaccess_trust_provider_id = aws_verifiedaccess_trust_provider.user.id
}

resource "aws_verifiedaccess_group" "rds" {
  verifiedaccess_instance_id = aws_verifiedaccess_instance.rds.id
  description                = var.group_description
  policy_document            = var.group_policy_document
  tags = {
    Name = var.verified_access_group_name
  }
  depends_on = [aws_verifiedaccess_instance_trust_provider_attachment.user]
}

resource "aws_security_group" "verified_access_endpoint" {
  name_prefix = "va-rds-endpoint-"
  description = "Security group for Verified Access endpoint ENIs"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow database access from approved CIDRs"
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    description = "Allow all egress from endpoint ENIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "aurora" {
  name_prefix = "va-aurora-"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL from Verified Access endpoint ENIs"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.verified_access_endpoint.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "aurora" {
  name_prefix = "va-aurora-"
  subnet_ids  = var.subnet_ids
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier_prefix = "va-aurora-"
  engine                    = "aurora-postgresql"
  engine_version            = var.aurora_engine_version
  database_name             = var.aurora_database_name
  master_username           = var.aurora_master_username
  master_password           = var.aurora_master_password
  db_subnet_group_name      = aws_db_subnet_group.aurora.name
  vpc_security_group_ids    = [aws_security_group.aurora.id]
  storage_encrypted         = true
  skip_final_snapshot       = true

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_serverless_min_capacity
    max_capacity = var.aurora_serverless_max_capacity
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier_prefix    = "va-aurora-"
  cluster_identifier   = aws_rds_cluster.aurora.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora.engine
  engine_version       = aws_rds_cluster.aurora.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora.name
}

resource "aws_verifiedaccess_endpoint" "rds" {
  application_domain       = local.use_custom_endpoint_domain ? var.application_domain : null
  attachment_type          = "vpc"
  description              = var.endpoint_description
  domain_certificate_arn   = local.use_custom_endpoint_domain ? var.domain_certificate_arn : null
  endpoint_domain_prefix   = local.use_custom_endpoint_domain ? var.endpoint_domain_prefix : null
  endpoint_type            = "rds"
  security_group_ids       = [aws_security_group.verified_access_endpoint.id]
  verified_access_group_id = aws_verifiedaccess_group.rds.id
  tags = {
    Name = var.verified_access_endpoint_name
  }

  rds_options {
    rds_endpoint       = aws_rds_cluster.aurora.endpoint
    rds_db_cluster_arn = aws_rds_cluster.aurora.arn
    port               = var.database_port
    protocol           = "tcp"
    subnet_ids         = var.subnet_ids
  }

  depends_on = [aws_verifiedaccess_instance_trust_provider_attachment.user]
}
