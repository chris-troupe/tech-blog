aws_region                           = "us-east-1"
vpc_id                               = "vpc-03ab42a1e2f60ffca"
subnet_ids                           = ["subnet-07b7ae2723eb7496f", "subnet-00fda9e7dc394db4f"]
database_port                        = 5432
allowed_cidrs                        = ["136.35.62.46/32"]
trust_provider_policy_reference_name = "idc"

# Optional descriptive overrides
# instance_description = "Verified Access instance for private database access"
# group_description    = "RDS access policy group"
# endpoint_description = "Verified Access endpoint for RDS"
verified_access_instance_name       = "test-va-instance"
verified_access_trust_provider_name = "test-va-idc-provider"
verified_access_group_name          = "test-va-group"
verified_access_endpoint_name       = "test-va-endpoint"
group_policy_document               = <<-EOT
permit(principal, action, resource)
when {
  context.idc.user.email != ""
};
EOT

# Aurora PostgreSQL Serverless v2
aurora_database_name           = "appdb"
aurora_master_username         = "postgres"
aurora_master_password         = "test-password"
aurora_serverless_min_capacity = 0.5
aurora_serverless_max_capacity = 1

# Leave these null to use AWS-generated Verified Access endpoint domain
application_domain     = null
endpoint_domain_prefix = null
domain_certificate_arn = null
