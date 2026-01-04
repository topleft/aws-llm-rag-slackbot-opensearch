import os
import sys

import pytest

# Set up test environment variables before any imports
os.environ.setdefault("SLACK_BOT_TOKEN", "test-slack-bot-token")
os.environ.setdefault("SLACK_SIGNING_SECRET", "test-slack-signing-secret")
os.environ.setdefault("SLACK_SLASH_COMMAND", "/test-llm")
os.environ.setdefault("KNOWLEDGEBASE_ID", "test-kb-123")
os.environ.setdefault("INFERENCE_PROFILE_ID", "test-model-arn")
os.environ.setdefault("AWS_REGION", "us-east-1")

# Add the handler directory to the Python path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from tests.test_kb_service import TestKnowledgeBaseService
from tests.test_main import TestMainHandler
from tests.test_slack_service import TestSlackService

if __name__ == "__main__":
    pytest.main(["-v", "--tb=short"])
