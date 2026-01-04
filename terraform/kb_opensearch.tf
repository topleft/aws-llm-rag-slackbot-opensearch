# Knowledge Base Module
module "knowledge_base" {
  source = "./modules/knowledgebase"

  # Core configuration
  kb_name               = "kb-${var.env}"
  kb_embedding_model_id = var.kb_embedding_model_id

  # Storage configuration
  storage_type                         = "OPENSEARCH_SERVERLESS"
  kb_source_data_s3_bucket_name_prefix = "kb-data-${var.env}"

  # OpenSearch configuration
  kb_oss_collection_name             = "kb-collection-${var.env}"
  enable_opensearch_standby_replicas = false
}

# Outputs for use by other resources
output "knowledge_base_id" {
  value       = module.knowledge_base.knowledge_base_id
  description = "The ID of the Knowledge Base"
}

output "knowledge_base_arn" {
  value       = module.knowledge_base.knowledge_base_arn
  description = "The ARN of the Knowledge Base"
}

output "s3_bucket_name" {
  value       = module.knowledge_base.s3_bucket_name
  description = "The name of the S3 bucket for knowledge base data"
}

output "opensearch_collection_endpoint" {
  value       = module.knowledge_base.opensearch_collection_endpoint
  description = "Endpoint for opensearch collection (used by provider)"
}

