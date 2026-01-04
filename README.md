# LLM Slack Bot with AWS Bedrock

A serverless Slack bot powered by AWS Bedrock that provides intelligent responses using large language models and knowledge base retrieval.

## 🔮 Features

- **Slack Integration**: Responds to slash commands in Slack channels
- **AWS Bedrock LLMs**: Leverages Amazon's foundation models (Nova, Titan)
- **Knowledge Base RAG**: Retrieval-Augmented Generation with document search
- **Serverless Architecture**: Built on AWS Lambda for scalability
- **Flexible Storage**: Support for both OpenSearch Serverless and S3 Vectors
- **Infrastructure as Code**: Fully managed with Terraform

## 📋 Prerequisites

- **AWS Account** with appropriate permissions
- **Slack Workspace** with admin access to create apps
- **Terraform** >= 1.0
- **Python** 3.9+ 
- **AWS CLI** configured
- **Make** (for build automation)

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Slack    │───▶│   API GW    │───▶│   AWS Lambda    │───▶│  AWS Bedrock    │
│             │    │             │    │                 │    │                 │
└─────────────┘    └─────────────┘    └─────────────────┘    └─────────────────┘
                                               │
                                               ▼
                                     ┌─────────────────┐
                                     │ Knowledge Base  │
                                     │ (OpenSearch/S3) │
                                     └─────────────────┘
```

## 🛠️ Setup

> ⚠️ **Cost Warning**: OpenSearch Serverless costs approximately $0.25/hour (~$180/month) when running. Consider using development environments sparingly or exploring alternative vector storage options for cost optimization. (s3 Vector storage example coming soon)

### 1. Configure AWS Profile

```bash
aws configure --profile {your-aws-profile-name}
export AWS_PROFILE={your-aws-profile-name}
export AWS_DEFAULT_REGION={your-aws-region}
```

### 2. Create Slack App

1. Go to [Slack API](https://api.slack.com/apps)
2. Create a new app from scratch
3. Add a slash command (e.g., `/ask-llm`)
4. Configure OAuth scopes: `commands`, `chat:write`
5. Install app to workspace
6. Note the **Bot User OAuth Token** and **Signing Secret**

### 3. Store Slack Credentials in AWS SSM

```bash
aws ssm put-parameter \
    --name "/slack/bot-token" \
    --value "UPDATE_ME" \
    --type "SecureString" \

aws ssm put-parameter \
    --name "/slack/signing-secret" \
    --value "UPDATE_ME" \
    --type "SecureString" \
```

### 4. Configure Environment

Create `terraform/config/env/dev.tfvars` and set required values:

```hcl
env = "dev"
slack_bot_token_parameter      = "/slack/bot-token"
slack_signing_secret_parameter = "/slack/signing-secret"
```

**Required Variables:**
- `slack_bot_token_parameter`: SSM parameter path for your Slack bot token
- `slack_signing_secret_parameter`: SSM parameter path for your Slack signing secret
- `kb_data_source_s3_bucket_name_prefix`: Unique S3 bucket prefix for knowledge base documents

## 🚀 Deployment

### Deploy

```bash
# Review plan
make plan_dev

# Deploy infrastructure
make apply_dev
```

### Configure Slack Endpoint

After deployment, configure your Slack slash command URL:
```
https://<api-gateway-id>.execute-api.<region>.amazonaws.com/dev/slack
```

## 📖 Usage

### Basic Commands

In Slack, use your configured slash command:

```
/ask-llm What is AWS Bedrock?
/ask-llm How do I deploy a Lambda function?
/ask-llm Explain machine learning concepts
```

### Knowledge Base

Upload documents to the S3 bucket to enable RAG responses:

```bash
# Copy files to knowledge base bucket
aws s3 cp documents/ s3://<kb_data_source_s3_bucket_name>/ --recursive

# Sync local directory with S3 bucket (preferred for updates)
aws s3 sync documents/ s3://<kb_data_source_s3_bucket_name>/

# Sync and trigger knowledge base ingestion
aws s3 sync documents/ s3://<kb_data_source_s3_bucket_name>/
aws bedrock-agent start-ingestion-job \
    --knowledge-base-id <knowledge-base-id> \
    --data-source-id <data-source-id>

# Get knowledge base details for IDs
aws bedrock-agent list-knowledge-bases
aws bedrock-agent list-data-sources --knowledge-base-id <knowledge-base-id>
```

## ⚙️ Configuration

### Terraform Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `env` | string | No | `dev` | Environment name |
| `slack_bot_token_parameter` | string | **Yes** | - | SSM parameter name for Slack bot token |
| `slack_signing_secret_parameter` | string | **Yes** | - | SSM parameter name for Slack signing secret |
| `slack_slash_command` | string | No | `/ask-llm` | Slack slash command trigger |
| `kb_model_id` | string | No | `amazon.titan-embed-text-v2:0` | Foundational model for knowledge base embeddings |
| `inference_profile_id` | string | No | `global.amazon.nova-2-lite-v1:0` | Inference profile for RAG model invocation |
| `rag_model_id` | string | No | `amazon.nova-2-lite-v1:0` | RAG model for retrieval-augmented generation |
| `kb_name` | string | No | `resourceKB` | Knowledge base name |
| `kb_data_source_s3_bucket_name_prefix` | string | **Yes** | - | S3 bucket prefix for knowledge base data |
| `kb_oss_collection_name` | string | No | `bedrock-resource-kb` | OpenSearch Serverless collection name |
| `enable_opensearch_standby_replicas` | bool | No | `false` | Enable standby replicas for OpenSearch |

### Terraform Outputs

| Output | Description |
|--------|-------------|
| `account_id` | AWS Account ID |
| `region` | AWS Region |
| `knowledge_base_id` | Knowledge Base ID for Lambda environment |
| `knowledge_base_arn` | Knowledge Base ARN for IAM policies |
| `kb_data_source_s3_bucket_name` | S3 bucket name for document uploads |
| `kb_data_source_id` | Knowledge Base Data Source ID |
| `opensearch_collection_endpoint` | OpenSearch collection endpoint |
| `api_invoke_url` | Invoke URL for the Slackbot API |

### Knowledge Base Storage

This project uses **OpenSearch Serverless** for vector storage and retrieval.


## 🔧 Development

### Project Structure

```
├── handler/                 # Lambda function code
│   ├── main.py             # Entry point
│   ├── kb_service.py       # Knowledge base integration
│   ├── parameter_service.py # AWS SSM parameter retrieval
│   └── requirements.txt    # Python dependencies
├── tests/                  # Test suite (excluded from Lambda package)
│   ├── conftest.py         # Test configuration and fixtures
│   ├── test_main.py        # Lambda handler tests
│   ├── test_kb_service.py  # Knowledge base service tests
│   ├── test_parameter_service.py # Parameter service tests
│   └── test_env.sh         # Test environment configuration
├── terraform/              # Infrastructure as Code
│   ├── modules/            # Reusable Terraform modules
│   ├── config/             # Environment configurations
│   ├── *.tf               # Terraform resources
│   └── Makefile           # Build automation
└── README.md              # This file
```

### Testing

The project includes a comprehensive test suite using pytest with full mocking of AWS services. Tests are located in the `tests/` directory and are automatically excluded from Lambda deployments.

#### Running Tests

```bash
# Run all tests
make test

# Run specific test file
python -m pytest tests/test_main.py -v
```

Tests use mocked AWS services via `moto` and don't require real AWS credentials or resources.
```

## Available Make Commands

```bash
make plan_dev      # Plan Terraform changes
make apply_dev     # Apply infrastructure 
make destroy_dev   # Destroy infrastructure
```


## Troubleshooting

### OpenSearch Provider URL Configuration

If you encounter an error where the OpenSearch provider URL is required or the `aws_opensearchserverless_collection.resource_kb.collection_endpoint` returns null, this is typically due to Terraform's dependency resolution during the initial plan phase.

**Solution**: Temporarily hardcode the collection endpoint URL in the OpenSearch provider configuration until the collection is fully provisioned, then reference the dynamic value in subsequent deployments.

```hcl
# Temporary workaround
provider "opensearch" {
    url = "https://your-collection-endpoint.region.aoss.amazonaws.com"
}

# Restore dynamic reference
provider "opensearch" {
    url = aws_opensearchserverless_collection.resource_kb.collection_endpoint
}
```

### Terraforn Destroy

Before running `make destroy_dev`, ensure all files are removed from the knowledge base data source S3 bucket. Terraform cannot destroy buckets that contain objects, which will cause the destroy operation to fail.

```bash
# Remove all objects from the knowledge base bucket
aws s3 rm s3://<kb_data_source_s3_bucket_name>/ --recursive

# Proceed with infrastructure destruction
make destroy_dev
```


## 🔐 Security

- All sensitive data stored in AWS SSM Parameter Store
- Lambda functions use least-privilege IAM roles
- API Gateway integration with request validation
- Slack request signature verification

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Resources

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Slack Bolt Framework](https://slack.dev/bolt-python/tutorial/getting-started)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Blog: Create a Generative AI Assistant](https://aws.amazon.com/blogs/machine-learning/create-a-generative-ai-assistant-with-slack-and-amazon-bedrock/)
- [AWS Blog: Deploy Amazon Bedrock Knowledge Base](https://aws.amazon.com/blogs/machine-learning/deploy-amazon-bedrock-knowledge-bases-using-terraform-for-rag-based-generative-ai-applications/)