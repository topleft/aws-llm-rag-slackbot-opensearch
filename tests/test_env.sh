# Testing Environment Configuration

# AWS Test Configuration
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test-access-key
export AWS_SECRET_ACCESS_KEY=test-secret-key
export AWS_SESSION_TOKEN=test-session-token

# Slack Test Configuration  
export SLACK_BOT_TOKEN_PARAMETER=/test/slack/bot-token
export SLACK_SIGNING_SECRET_PARAMETER=/test/slack/signing-secret
export SLACK_SLASH_COMMAND=/test-llm

# Bedrock Test Configuration
export KNOWLEDGEBASE_ID=test-kb-123
export INFERENCE_PROFILE_ID=test-model-arn

echo "Test environment configured"