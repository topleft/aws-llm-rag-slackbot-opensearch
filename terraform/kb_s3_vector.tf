# # Knowledge Base Module with S3 Vectors Storage
# module "knowledge_base_s3_vector" {
#   source = "./modules/knowledgebase"

#   # Core configuration
#   kb_name                                = "s3vector-kb-${var.env}"
#   kb_embedding_model_id                           = "amazon.titan-embed-text-v2:0"

#   # Storage configuration - S3 Vectors
#   storage_type                          = "S3_VECTORS"
#   kb_source_data_s3_bucket_name_prefix = "s3vector-kb-data-${var.env}-"

#   # S3 Vectors configuration
#   s3_vector_embedding_dimensions       = 1024
#   s3_vector_distance_metric           = "cosine"

#   # OpenSearch configuration (not used but required variables)
#   kb_oss_collection_name               = "unused-for-s3vectors"
#   enable_opensearch_standby_replicas   = false
# }

# # Outputs for S3 Vector Knowledge Base
# output "s3_vector_knowledge_base_id" {
#   value       = module.knowledge_base_s3_vector.knowledge_base_id
#   description = "The ID of the S3 Vector Knowledge Base"
# }

# output "s3_vector_knowledge_base_arn" {
#   value       = module.knowledge_base_s3_vector.knowledge_base_ARN
#   description = "The ARN of the S3 Vector Knowledge Base"
# }

# output "s3_vector_s3_bucket_name" {
#   value       = module.knowledge_base_s3_vector.s3_bucket_name
#   description = "The name of the S3 bucket for S3 vector knowledge base data"
# }

# output "s3_vector_bucket_arn" {
#   value       = module.knowledge_base_s3_vector.s3_vector_bucket_arn
#   description = "The ARN of the S3 vector bucket"
# }

# output "s3_vector_index_arn" {
#   value       = module.knowledge_base_s3_vector.s3_vector_index_arn
#   description = "The ARN of the S3 vector index"
# }