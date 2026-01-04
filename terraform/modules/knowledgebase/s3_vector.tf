# S3 Vector Store Configuration for Knowledge Base
resource "aws_s3vectors_vector_bucket" "resource_kb" {
  count              = var.storage_type == "S3_VECTORS" ? 1 : 0
  vector_bucket_name = "${local.bedrock_kb_name}-vectors"
}

resource "aws_s3vectors_index" "resource_kb" {
  count              = var.storage_type == "S3_VECTORS" ? 1 : 0
  index_name         = "${local.bedrock_kb_name}-index"
  vector_bucket_name = aws_s3vectors_vector_bucket.resource_kb[0].vector_bucket_name

  data_type       = "float32"
  dimension       = var.s3_vector_embedding_dimensions
  distance_metric = var.s3_vector_distance_metric
}

# IAM role policy for S3 Vectors access
resource "aws_iam_role_policy" "bedrock_kb_resource_kb_s3vectors" {
  count = var.storage_type == "S3_VECTORS" ? 1 : 0
  name  = "AmazonBedrockS3VectorsPolicyForKnowledgeBase_${local.bedrock_kb_name}"
  role  = aws_iam_role.bedrock_kb_resource_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3VectorsStatement"
        Action   = [
          "s3vectors:*"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3vectors_vector_bucket.resource_kb[0].vector_bucket_arn,
          "${aws_s3vectors_vector_bucket.resource_kb[0].vector_bucket_arn}/*",
          aws_s3vectors_index.resource_kb[0].index_arn
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}