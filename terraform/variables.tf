variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "slack_bot_token_parameter" {
  description = "The SSM parameter name for the Slack bot token."
  type        = string
}

variable "slack_signing_secret_parameter" {
  description = "The SSM parameter name for the Slack signing secret."
  type        = string
}

variable "slack_slash_command" {
  description = "The Slack slash command to trigger the LLM Slackbot."
  type        = string
  default     = "/ask-llm"

}

variable "kb_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "inference_profile_id" {
  description = "The ID of the inference profile used for RAG model invocation."
  type        = string
  default     = "global.amazon.nova-2-lite-v1:0"
}

variable "rag_model_id" {
  description = "The ID of the RAG model used for retrieval-augmented generation."
  type        = string
  default     = "amazon.nova-2-lite-v1:0"
}

variable "kb_name" {
  description = "The knowledge base name."
  type        = string
  default     = "resourceKB"
}

variable "kb_s3_bucket_name_prefix" {
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