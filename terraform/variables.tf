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

variable "kb_embedding_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}