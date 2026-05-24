# Verified Access Intro Stack

This repository is part of a blog series and serves as an introduction to **AWS Verified Access** for private database access.

It provisions a minimal end-to-end path for:
- IAM Identity Center-backed Verified Access trust
- Verified Access instance/group/endpoint
- Aurora PostgreSQL Serverless v2
- Security groups and subnet group wiring

## What This Deploys

At a high level, the stack creates:
1. A `aws_verifiedaccess_instance`
2. A user trust provider (`aws_verifiedaccess_trust_provider`) using IAM Identity Center
3. A trust-provider attachment to the instance
4. A Verified Access group with a Cedar policy
5. A Verified Access endpoint of type `rds`
6. An Aurora PostgreSQL Serverless v2 cluster + serverless instance
7. Security groups allowing client -> Verified Access endpoint and endpoint -> Aurora

Current policy in `sample.tfvars` allows any authenticated IAM Identity Center user in the configured trust context.

## Prerequisites

Before running this as a new user, make sure you have:

1. **OpenTofu installed**
- `tofu` available in PATH

2. **AWS credentials configured**
- Ability to create EC2 Verified Access, RDS, IAM Identity Center-integrated resources, and security groups
- Target region (default in this repo: `us-east-1`)

3. **IAM Identity Center available in your AWS organization/account context**
- Verified Access trust provider will use IAM Identity Center as `user_trust_provider_type`
- Users should be able to authenticate in Identity Center

4. **VPC/Subnets selected**
- Private subnets recommended
- Values provided via `sample.tfvars`

5. **Client egress IP known**
- Add your public IP as `/32` in `allowed_cidrs` or you will not be able to connect

## Quick Start

1. Initialize:
```bash
tofu init
```

2. Create your local tfvars from the sample:
```bash
cp sample.tfvars terraform.tfvars
```

3. Review variables in `terraform.tfvars`:
- `vpc_id`
- `subnet_ids`
- `allowed_cidrs`
- `database_port` (5432 by default)
- naming variables for Verified Access resources
- Aurora credentials/settings

4. Plan:
```bash
tofu plan
```

5. Apply:
```bash
tofu apply
```

## Validate and Connect

After apply:

1. Get endpoint + DB details:
```bash
tofu output verified_access_endpoint_domain
tofu output aurora_cluster_endpoint
```

2. Test TCP reachability:
```bash
nc -vz <verified_access_endpoint_domain> 5432
```

3. Connect with `psql`:
```bash
PGPASSWORD='test-password' psql \
  "host=<verified_access_endpoint_domain> port=5432 dbname=appdb user=postgres sslmode=require"
```

## Important Notes

- This is an intro/demo stack for learning and blog walkthrough purposes.
- The default DB password in this repo is intentionally simple for demo (`test-password`). Change it for any non-demo use.
- `group_policy_document` currently allows any authenticated user in your IAM Identity Center trust context. Tighten this for production.
- Endpoint creation can take several minutes.

## Common Troubleshooting

1. **"Must attach a TrustProvider to Instance before you can create a Group"**
- Ensure group creation depends on trust provider attachment (already configured in this repo).

2. **"Missing required parameter RdsEndpoint in RdsOptions"**
- Ensure `rds_options.rds_endpoint` is set (already configured in this repo).

3. **Endpoint created but connection fails**
- Verify your source IP still matches `allowed_cidrs`
- Verify Verified Access endpoint status is active
- Verify IAM Identity Center login/session is valid
- Verify Aurora is available and credentials are correct

## Suggested Next Hardening Steps

1. Use AWS Secrets Manager for DB credentials instead of plaintext variables.
2. Restrict Cedar policy to email domain and/or group claims.
3. Add remote state backend and locking.
4. Add environment-specific workspaces or separate state per environment.
5. Add CloudWatch alarms/logging around RDS availability and connection failures.
