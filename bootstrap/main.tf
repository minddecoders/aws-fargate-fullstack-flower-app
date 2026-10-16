terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# ============================================================================
# 🛰️ 1. GLOBAL OIDC IDENTITY PROVIDER HOOK
# ============================================================================
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # Standard trusted thumbprints for GitHub Actions OIDC
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# ============================================================================
# 🛡️ 2. PERMANENT KEYLESS EXECUTION ROLE ASSUMED BY GITHUB ACTIONS
# ============================================================================
resource "aws_iam_role" "github_oidc_role" {
  name        = "sidra-github-actions-oidc-execution-role"
  description = "Role assumed by GitHub Actions runners using temporary OIDC credentials for the full-stack application"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Trust only the project's GitHub repository events
            "token.actions.githubusercontent.com:sub" = [
              "repo:minddecoders*/aws-fargate-fullstack-flower-app*:*"
            ]
          }
        }
      }
    ]
  })
}

# ============================================================================
# 🛡️ 3. ATTACH ADMINISTRATOR PERMISSION POLICY WIRE
# ============================================================================
resource "aws_iam_role_policy_attachment" "oidc_admin_attach" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# 📡 PHASE 8 TELEMETRY OUTPUT
# ============================================================================
output "github_actions_oidc_role_arn" {
  value       = aws_iam_role.github_oidc_role.arn
  description = "The target IAM role ARN used by GitHub Actions for temporary AWS credentials"
}

# ============================================================================
# PHASE 10: INFRASTRUCTURE STATE STORAGE VAULT
# ============================================================================

# 1. References or declares your central S3 state bucket
resource "aws_s3_bucket" "state_vault" {
  bucket        = "sidra-prod-state-vault-2026"
  force_destroy = false

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
    Security    = "Versioned-State-Vault"
    Project     = "AWS-Fargate-Fullstack-App"
  }
}

# 2. Enables S3 object versioning for Terraform state recovery
resource "aws_s3_bucket_versioning" "state_vault_versioning" {
  bucket = aws_s3_bucket.state_vault.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================================================
# PHASE 11: SECRETS PROTECTION • KMS ENCRYPTION
# ============================================================================

# 🔐 1. Create a dedicated customer-managed AWS KMS encryption key
resource "aws_kms_key" "sidra_vault_key" {
  description             = "Customer-managed key for encrypting full-stack application secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
    Protection  = "KMS-Cryptographic-Shield"
    Project     = "AWS-Fargate-Fullstack-App"
  }
}

# 🏷️ 2. Create a readable alias for the KMS key
resource "aws_kms_alias" "sidra_vault_key_alias" {
  name          = "alias/fullstack-microservices-vault-key"
  target_key_id = aws_kms_key.sidra_vault_key.key_id
}

# 🗄️ 3. Create the AWS Secrets Manager secret container
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "sidra-fullstack-microservices-db-secrets"
  description             = "Encrypted credential store for the full-stack microservices application"
  kms_key_id              = aws_kms_key.sidra_vault_key.arn
  recovery_window_in_days = 0

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
    Project     = "AWS-Fargate-Fullstack-App"
  }
}

# ============================================================================
# PHASE 11 TELEMETRY OUTPUTS: SECURITY IDENTIFIERS
# ============================================================================
output "kms_key_arn" {
  value       = aws_kms_key.sidra_vault_key.arn
  description = "The Amazon Resource Name of the KMS encryption key"
}

output "secrets_manager_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "The Amazon Resource Name of the full-stack application's Secrets Manager secret"
}