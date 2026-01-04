
variable "kb_embedding_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}


variable "kb_name" {
  description = "The knowledge base name."
  type        = string
  default     = "resourceKB"
}

variable "kb_source_data_s3_bucket_name_prefix" {
  description = "The name prefix of the S3 bucket for the data source of the knowledge base."
  type        = string
}

variable "kb_oss_collection_name" {
  description = "The name of the OSS collection for the knowledge base."
  type        = string
  default     = "bedrock-resource-kb"
}

variable "enable_opensearch_standby_replicas" {
  description = "Enable standby replicas for OpenSearch Serverless collection."
  type        = bool
  default     = false
}

variable "storage_type" {
  description = "The storage type for the knowledge base. Valid values are 'OPENSEARCH_SERVERLESS' or 'S3_VECTORS'."
  type        = string
  default     = "OPENSEARCH_SERVERLESS"
  validation {
    condition     = can(regex("^(OPENSEARCH_SERVERLESS|S3_VECTORS)$", var.storage_type))
    error_message = "storage_type must be either 'OPENSEARCH_SERVERLESS' or 'S3_VECTORS'."
  }
}

variable "s3_vector_embedding_dimensions" {
  description = "The dimensions for the embedding model when using S3 Vectors."
  type        = number
  default     = 256
}

variable "s3_vector_distance_metric" {
  description = "The distance metric for S3 Vectors index."
  type        = string
  default     = "cosine"
  validation {
    condition     = can(regex("^(cosine|euclidean|dot_product)$", var.s3_vector_distance_metric))
    error_message = "distance_metric must be one of: cosine, euclidean, dot_product."
  }
}