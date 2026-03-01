variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "juice-shop-demo"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID (must auto-assign public IPs or we set associate_public_ip_address=true)"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your IP in CIDR form for SSH (e.g., 203.0.113.5/32)"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "dns_account_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "dns_hosted_zone_id" {
  type = string
}
