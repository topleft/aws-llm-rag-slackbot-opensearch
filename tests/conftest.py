import json
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, Mock, patch

import boto3
import pytest
from moto import mock_aws

# Add handler directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "handler"))

# Set AWS credentials for testing
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"


# Test fixtures for common mocks
@pytest.fixture
def mock_env_vars():
    """Mock environment variables"""
    env_vars = {
        "SLACK_BOT_TOKEN_PARAMETER": "/test/slack/bot-token",
        "SLACK_SIGNING_SECRET_PARAMETER": "/test/slack/signing-secret",
        "SLACK_SLASH_COMMAND": "/test-llm",
        "KNOWLEDGEBASE_ID": "test-kb-123",
        "INFERENCE_PROFILE_ID": "test-model-arn",
        "AWS_REGION": "us-east-1",
    }
    with patch.dict(os.environ, env_vars):
        yield env_vars


@pytest.fixture
def mock_bedrock_response():
    """Mock Bedrock knowledge base response"""
    return {
        "output": {"text": "This is a test response from Bedrock Knowledge Base."},
        "citations": [],
        "guardrailAction": "NONE",
    }


@pytest.fixture
def mock_slack_event():
    """Mock Slack slash command event"""
    return {
        "body": "command=%2Ftest-llm&text=test+query&user_id=U123456&team_id=T123456",
        "headers": {
            "X-Slack-Signature": "v0=test-signature",
            "X-Slack-Request-Timestamp": "1234567890",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        "isBase64Encoded": False,
    }


@pytest.fixture
def mock_slack_body():
    """Mock parsed Slack body"""
    return {
        "command": "/test-llm",
        "text": "test query",
        "user_id": "U123456",
        "team_id": "T123456",
    }
