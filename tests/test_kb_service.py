import sys
from pathlib import Path
from unittest.mock import MagicMock, Mock, patch

import boto3
import pytest

# Add handler directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "handler"))
from kb_service import get_bedrock_knowledge_base_response


class TestKnowledgeBaseService:
    """Test knowledge base service functionality"""

    @patch("kb_service.boto3.client")
    def test_get_bedrock_knowledge_base_response_success(
        self, mock_boto_client, mock_env_vars, mock_bedrock_response
    ):
        """Test successful knowledge base response"""
        # Mock the bedrock client
        mock_client = Mock()
        mock_boto_client.return_value = mock_client
        mock_client.retrieve_and_generate.return_value = mock_bedrock_response

        result = get_bedrock_knowledge_base_response("test query")

        # Verify client was created correctly
        mock_boto_client.assert_called_with(
            service_name="bedrock-agent-runtime", region_name="us-east-1"
        )

        # Verify the API call was made correctly
        mock_client.retrieve_and_generate.assert_called_once()
        call_args = mock_client.retrieve_and_generate.call_args

        # Check input parameter
        assert call_args.kwargs["input"]["text"] == "test query"

        # Check configuration
        config = call_args.kwargs["retrieveAndGenerateConfiguration"]
        assert config["type"] == "KNOWLEDGE_BASE"
        assert config["knowledgeBaseConfiguration"]["knowledgeBaseId"] == "test-kb-123"
        assert config["knowledgeBaseConfiguration"]["modelArn"] == "test-model-arn"

        # Verify response
        assert result == mock_bedrock_response

    @patch("kb_service.boto3.client")
    def test_get_bedrock_knowledge_base_response_client_error(
        self, mock_boto_client, mock_env_vars
    ):
        """Test handling of Bedrock client errors"""
        mock_client = Mock()
        mock_boto_client.return_value = mock_client
        mock_client.retrieve_and_generate.side_effect = Exception("Bedrock API Error")

        with pytest.raises(Exception) as exc_info:
            get_bedrock_knowledge_base_response("test query")

        assert "Bedrock API Error" in str(exc_info.value)

    @patch("kb_service.boto3.client")
    def test_get_bedrock_knowledge_base_response_empty_query(
        self, mock_boto_client, mock_env_vars, mock_bedrock_response
    ):
        """Test handling of empty query"""
        mock_client = Mock()
        mock_boto_client.return_value = mock_client
        mock_client.retrieve_and_generate.return_value = mock_bedrock_response

        result = get_bedrock_knowledge_base_response("")

        # Should still call the API with empty string
        mock_client.retrieve_and_generate.assert_called_once()
        call_args = mock_client.retrieve_and_generate.call_args
        assert call_args.kwargs["input"]["text"] == ""

    @patch("kb_service.logging")
    @patch("kb_service.boto3.client")
    def test_logging_behavior(
        self, mock_boto_client, mock_logging, mock_env_vars, mock_bedrock_response
    ):
        """Test that responses are logged correctly"""
        mock_client = Mock()
        mock_boto_client.return_value = mock_client
        mock_client.retrieve_and_generate.return_value = mock_bedrock_response

        get_bedrock_knowledge_base_response("test query")

        # Verify logging was called
        mock_logging.info.assert_called_once()
        log_call = mock_logging.info.call_args[0][0]
        assert "Bedrock Knowledge Base Response:" in log_call
