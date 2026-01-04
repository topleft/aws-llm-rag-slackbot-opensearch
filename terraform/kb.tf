# Use data sources to get common information about the environment
data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  account_id             = data.aws_caller_identity.this.account_id
  region                 = data.aws_region.this.region
  bedrock_model_arn      = "arn:aws:bedrock:${local.region}::foundation-model/${var.kb_model_id}"
  bedrock_kb_name        = "${var.kb_name}-${var.env}"
  kb_oss_collection_name = "${var.kb_oss_collection_name}-${var.env}"
}

# Knowledge base resource role
resource "aws_iam_role" "bedrock_kb_resource_kb" {
  name = "AmazonBedrockExecutionRoleForKnowledgeBase_${local.bedrock_kb_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${local.region}:${local.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

# Knowledge base bedrock invoke policy
resource "aws_iam_role_policy" "bedrock_kb_resource_kb_model" {
  name = "AmazonBedrockFoundationModelPolicyForKnowledgeBase_${local.bedrock_kb_name}"
  role = aws_iam_role.bedrock_kb_resource_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = local.bedrock_model_arn
      }
    ]
  })
}


# Knowledge base S3 policy
resource "aws_iam_role_policy" "bedrock_kb_resource_kb_s3" {
  name = "AmazonBedrockS3PolicyForKnowledgeBase_${local.bedrock_kb_name}"
  role = aws_iam_role.bedrock_kb_resource_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListBucketStatement"
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = aws_s3_bucket.resource_kb.arn
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
      } },
      {
        Sid      = "S3GetObjectStatement"
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.resource_kb.arn}/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}

# Knowledge base opensearch access policy
resource "aws_iam_role_policy" "bedrock_kb_resource_kb_oss" {
  name = "AmazonBedrockOSSPolicyForKnowledgeBase_${local.bedrock_kb_name}"
  role = aws_iam_role.bedrock_kb_resource_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "aoss:APIAccessAll"
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.resource_kb.arn
      }
    ]
  })
}

# S3 bucket data source
resource "aws_s3_bucket" "resource_kb" {
  bucket_prefix = "${var.kb_data_source_s3_bucket_name_prefix}-${var.env}"
}

# Knowledge base resource creation
resource "aws_bedrockagent_knowledge_base" "resource_kb" {
  name     = local.bedrock_kb_name
  role_arn = aws_iam_role.bedrock_kb_resource_kb.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = local.bedrock_model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.resource_kb.arn
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy.bedrock_kb_resource_kb_model,
    aws_iam_role_policy.bedrock_kb_resource_kb_s3,
    opensearch_index.resource_kb,
    time_sleep.aws_iam_role_policy_bedrock_kb_resource_kb_oss
  ]
}

resource "aws_bedrockagent_data_source" "resource_kb" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.resource_kb.id
  name              = "${local.bedrock_kb_name}DataSource"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.resource_kb.arn
    }
  }
}

