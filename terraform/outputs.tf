# ===================
# Infrastructure Outputs
# ===================

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.this.account_id
}

output "region" {
  description = "AWS Region"
  value       = local.region
}

# ===================
# API Gateway Outputs
# ===================

output "api_invoke_url" {
  description = "Invoke URL for the Slackbot API"
  value       = "${aws_api_gateway_stage.example.invoke_url}/slackbot"
}

# ===================
# Knowledge Base Outputs
# ===================

output "knowledge_base_id" {
  description = "The ID of the Knowledge Base for Lambda environment"
  value       = aws_bedrockagent_knowledge_base.resource_kb.id
}

output "knowledge_base_arn" {
  description = "The ARN of the Knowledge Base for IAM policies"
  value       = aws_bedrockagent_knowledge_base.resource_kb.arn
}

output "kb_data_source_id" {
  description = "The ID of the Knowledge Base Data Source"
  value       = aws_bedrockagent_data_source.resource_kb.data_source_id
}

output "kb_data_source_s3_bucket_name" {
  description = "S3 bucket name for Knowledge Base document uploads"
  value       = aws_s3_bucket.resource_kb.bucket
}

# ===================
# OpenSearch Outputs
# ===================

output "opensearch_collection_endpoint" {
  description = "OpenSearch collection endpoint for provider configuration"
  value       = aws_opensearchserverless_collection.resource_kb.collection_endpoint
}