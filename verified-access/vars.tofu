variable "aws_region" {
  description = "AWS region for Verified Access resources."
  type        = string
  default     = "us-east-1"
}

variable "instance_description" {
  description = "Description for the Verified Access instance."
  type        = string
  default     = "Verified Access instance for private database access"
}

variable "verified_access_instance_name" {
  description = "Name tag for the Verified Access instance."
  type        = string
  default     = "va-rds-instance"
}

variable "group_description" {
  description = "Description for the Verified Access group protecting the RDS path."
  type        = string
  default     = "RDS access policy group"
}

variable "verified_access_group_name" {
  description = "Name tag for the Verified Access group."
  type        = string
  default     = "va-rds-group"
}

variable "endpoint_description" {
  description = "Description for the Verified Access endpoint."
  type        = string
  default     = "Verified Access endpoint for RDS"
}

variable "verified_access_endpoint_name" {
  description = "Name tag for the Verified Access endpoint."
  type        = string
  default     = "va-rds-endpoint"
}

variable "trust_provider_description" {
  description = "Description for the Verified Access trust provider."
  type        = string
  default     = "IAM Identity Center trust provider"
}

variable "verified_access_trust_provider_name" {
  description = "Name tag for the Verified Access trust provider."
  type        = string
  default     = "va-idc-trust-provider"
}

variable "trust_provider_policy_reference_name" {
  description = "Identifier used in Verified Access policy rules for this trust provider."
  type        = string
  default     = "idc"
}

variable "vpc_id" {
  description = "VPC ID where the endpoint ENIs will be created."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the Verified Access endpoint."
  type        = list(string)
}

variable "database_port" {
  description = "Database listener port. Example: 5432 for Postgres, 3306 for MySQL."
  type        = number
  default     = 5432
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to initiate database sessions through the endpoint."
  type        = list(string)
  default     = []
}

variable "application_domain" {
  description = "Optional custom application domain published by Verified Access (for example db.lodasmarkets.com)."
  type        = string
  default     = null
}

variable "endpoint_domain_prefix" {
  description = "Optional unique prefix for the Verified Access endpoint domain (used with custom domain)."
  type        = string
  default     = null
}

variable "domain_certificate_arn" {
  description = "Optional ACM certificate ARN for the Verified Access endpoint custom domain."
  type        = string
  default     = null
}

variable "group_policy_document" {
  description = "Optional Cedar policy for the Verified Access group. If null, a default company-email policy is used."
  type        = string
  default     = null
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version for the serverless v2 cluster."
  type        = string
  default     = "17.7"
}

variable "aurora_database_name" {
  description = "Initial database name in the Aurora cluster."
  type        = string
  default     = "appdb"
}

variable "aurora_master_username" {
  description = "Master username for the Aurora cluster."
  type        = string
  default     = "postgres"
}

variable "aurora_master_password" {
  description = "Master password for the Aurora cluster."
  type        = string
  default     = "test-password"
  sensitive   = true
}

variable "aurora_serverless_min_capacity" {
  description = "Minimum Aurora Serverless v2 ACU."
  type        = number
  default     = 0.5
}

variable "aurora_serverless_max_capacity" {
  description = "Maximum Aurora Serverless v2 ACU."
  type        = number
  default     = 1
}
