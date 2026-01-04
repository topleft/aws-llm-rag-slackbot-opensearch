# Knowledge base opensearch access policy
resource "aws_iam_role_policy" "bedrock_kb_resource_kb_oss" {
  count = var.storage_type == "OPENSEARCH_SERVERLESS" ? 1 : 0
  name = "AmazonBedrockOSSPolicyForKnowledgeBase_${local.bedrock_kb_name}"
  role = aws_iam_role.bedrock_kb_resource_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "aoss:APIAccessAll"
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.resource_kb[0].arn
      }
    ]
  })
}

# OpenSearch collection access policy
resource "aws_opensearchserverless_access_policy" "resource_kb" {
  count = var.storage_type == "OPENSEARCH_SERVERLESS" ? 1 : 0
  name = local.kb_oss_collection_name
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/${local.kb_oss_collection_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex", # Required for Terraform
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:WriteDocument"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = [
        aws_iam_role.bedrock_kb_resource_kb.arn,
        data.aws_caller_identity.this.arn
      ]
    }
  ])
}

# OpenSearch collection data encryption policy
resource "aws_opensearchserverless_security_policy" "resource_kb_encryption" {
  count = var.storage_type == "OPENSEARCH_SERVERLESS" ? 1 : 0
  name = local.kb_oss_collection_name
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${local.kb_oss_collection_name}"
        ]
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

# OpenSearch collection network policy
resource "aws_opensearchserverless_security_policy" "resource_kb_network" {
  count = var.storage_type == "OPENSEARCH_SERVERLESS" ? 1 : 0
  name = local.kb_oss_collection_name
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# OpenSearch resource 
resource "aws_opensearchserverless_collection" "resource_kb" {
  count            = var.storage_type == "OPENSEARCH_SERVERLESS" ? 1 : 0
  name             = local.kb_oss_collection_name
  type             = "VECTORSEARCH"
  standby_replicas = var.enable_opensearch_standby_replicas ? "ENABLED" : "DISABLED"
  depends_on = [
    aws_opensearchserverless_access_policy.resource_kb[0],
    aws_opensearchserverless_security_policy.resource_kb_encryption[0],
    aws_opensearchserverless_security_policy.resource_kb_network[0]
  ]
}

# Note: opensearch provider uses an output from the knowledgebase collection 
# and therefore cannot be created until the collection exists.
# 
# Because providers cannot have meta-arguments (depends_on, count, for_each) 
# the terraform will have to be run twice to first populate the aws opensearch 
# collection endpoint and then second to consume that endpoint in the open search index creation. 

locals {
  is_collection_created = try(aws_opensearchserverless_collection.resource_kb[0].collection_endpoint != null, false)
  configure_opensearch = var.storage_type == "OPENSEARCH_SERVERLESS" && local.is_collection_created ? true : false
}

# provider "opensearch" {
#   url         = aws_opensearchserverless_collection.resource_kb[0].collection_endpoint
#   healthcheck = false
# }

# OpenSearch index creation
# resource "opensearch_index" "resource_kb" {
#   count                          = local.configure_opensearch ? 1 : 0
#   name                           = "bedrock-knowledge-base-default-index"
#   number_of_shards               = "2"
#   number_of_replicas             = "0"
#   index_knn                      = true
#   index_knn_algo_param_ef_search = "512"
#   mappings                       = <<-EOF
#     {
#       "properties": {
#         "bedrock-knowledge-base-default-vector": {
#           "type": "knn_vector",
#           "dimension": 1024,
#           "method": {
#             "name": "hnsw",
#             "engine": "faiss",
#             "parameters": {
#               "m": 16,
#               "ef_construction": 512
#             },
#             "space_type": "l2"
#           }
#         },
#         "AMAZON_BEDROCK_METADATA": {
#           "type": "text",
#           "index": "false"
#         },
#         "AMAZON_BEDROCK_TEXT_CHUNK": {
#           "type": "text",
#           "index": "true"
#         }
#       }
#     }
#   EOF
#   force_destroy                  = true
#   depends_on                     = [aws_opensearchserverless_collection.resource_kb[0]]
# }

resource "time_sleep" "aws_iam_role_policy_bedrock_kb_resource_kb_oss" {
  count           = var.storage_type == "OPENSEARCH_SERVERLESS" ? 1 : 0
  create_duration = "20s"
  depends_on      = [aws_iam_role_policy.bedrock_kb_resource_kb_oss[0]]
}

output "opensearch_collection_endpoint" {
  value = local.configure_opensearch ? aws_opensearchserverless_collection.resource_kb[0].collection_endpoint : null
}