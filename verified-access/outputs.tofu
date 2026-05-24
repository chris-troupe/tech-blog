output "verified_access_instance_id" {
  description = "ID of the Verified Access instance."
  value       = aws_verifiedaccess_instance.rds.id
}

output "verified_access_group_id" {
  description = "ID of the Verified Access group for database access."
  value       = aws_verifiedaccess_group.rds.id
}

output "verified_access_endpoint_id" {
  description = "ID of the Verified Access endpoint."
  value       = aws_verifiedaccess_endpoint.rds.id
}

output "verified_access_endpoint_domain" {
  description = "DNS name created by Verified Access for database connectivity."
  value       = aws_verifiedaccess_endpoint.rds.endpoint_domain
}

output "verified_access_trust_provider_id" {
  description = "ID of the Verified Access trust provider."
  value       = aws_verifiedaccess_trust_provider.user.id
}

output "aurora_cluster_endpoint" {
  description = "Writer endpoint of the Aurora PostgreSQL cluster."
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora PostgreSQL cluster."
  value       = aws_rds_cluster.aurora.reader_endpoint
}
