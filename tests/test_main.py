import json
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, Mock, patch

import pytest

# Add handler directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "handler"))

# Mock get_parameter and Slack App before importing main
with patch("parameter_service.get_parameter") as mock_get_param, patch(
    "slack_bolt.App"
) as mock_slack_app:
    mock_get_param.side_effect = ["xoxb-test-token", "test-signing-secret"]
    mock_app_instance = Mock()
    mock_slack_app.return_value = mock_app_instance
    # Now safe to import main
    import main


class TestMainHandler:
    """Test main handler and Slack integration"""

    @patch("main.get_parameter")
    @patch("main.get_bedrock_knowledge_base_response")
    def test_process_command_request_success(
        self, mock_kb_service, mock_get_parameter, mock_env_vars, mock_bedrock_response
    ):
        """Test successful command processing"""
        # Setup mocks
        mock_get_parameter.side_effect = ["xoxb-test-token", "test-signing-secret"]
        mock_kb_service.return_value = mock_bedrock_response

        # Mock the respond function
        mock_respond = Mock()
        mock_body = {"text": "test query"}

        # Execute the function directly
        main.process_command_request(mock_respond, mock_body)

        # Verify KB service was called
        mock_kb_service.assert_called_once_with("test query")

        # Verify response was called with correct format
        mock_respond.assert_called_once()
        response_call = mock_respond.call_args[0][0]

        assert "blocks" in response_call
        assert len(response_call["blocks"]) == 1
        assert response_call["blocks"][0]["type"] == "section"
        assert response_call["blocks"][0]["text"]["type"] == "mrkdwn"
        assert "/test-llm" in response_call["blocks"][0]["text"]["text"]
        assert "Response:" in response_call["blocks"][0]["text"]["text"]

    @patch("main.get_parameter")
    @patch("main.get_bedrock_knowledge_base_response")
    def test_process_command_request_kb_error(
        self, mock_kb_service, mock_get_parameter, mock_env_vars
    ):
        """Test handling of knowledge base errors"""
        # Setup mocks
        mock_get_parameter.side_effect = ["xoxb-test-token", "test-signing-secret"]
        mock_kb_service.side_effect = Exception("KB Error")

        mock_respond = Mock()
        mock_body = {"text": "test query"}

        # Execute the function directly
        main.process_command_request(mock_respond, mock_body)

        # Verify error response
        mock_respond.assert_called_once()
        error_message = mock_respond.call_args[0][0]
        assert "Sorry an error occurred" in error_message
        assert "KB Error" in error_message

    def test_respond_to_slack_within_3_seconds_with_text(self, mock_env_vars):
        """Test ACK response with valid text"""
        mock_ack = Mock()
        mock_body = {"text": "test query"}

        main.respond_to_slack_within_3_seconds(mock_body, mock_ack)

        mock_ack.assert_called_once()
        ack_message = mock_ack.call_args[0][0]
        assert "Accepted Task" in ack_message
        assert ":hourglass_flowing_sand:" in ack_message

    def test_respond_to_slack_within_3_seconds_no_text(self, mock_env_vars):
        """Test ACK response with missing text"""
        mock_ack = Mock()
        mock_body = {}  # No text field

        main.respond_to_slack_within_3_seconds(mock_body, mock_ack)

        mock_ack.assert_called_once()
        ack_message = mock_ack.call_args[0][0]
        assert ":x: Usage:" in ack_message
        assert "/test-llm" in ack_message

    @patch("main.App")  # Patch where it's used, not where it's imported
    @patch("main.SlackRequestHandler")
    @patch("main.get_parameter")
    def test_lambda_handler(
        self, mock_get_parameter, mock_slack_handler, mock_slack_app, mock_env_vars
    ):
        """Test Lambda handler integration"""
        # Setup mocks
        mock_get_parameter.side_effect = ["xoxb-test-token", "test-signing-secret"]
        mock_app_instance = Mock()
        mock_slack_app.return_value = mock_app_instance

        mock_handler_instance = Mock()
        mock_slack_handler.return_value = mock_handler_instance
        mock_handler_instance.handle.return_value = {"statusCode": 200}

        # Reset app to None to force recreation
        main.app = None

        # Test event and context
        test_event = {"body": "test-body"}
        test_context = {"aws_request_id": "test-123"}

        result = main.handler(test_event, test_context)

        # Verify App was called
        mock_slack_app.assert_called_once()

        # Verify handler was called correctly
        mock_handler_instance.handle.assert_called_once_with(test_event, test_context)
        assert result == {"statusCode": 200}

    @patch("main.App")  # Patch where it's used, not where it's imported
    @patch("main.get_parameter")
    def test_app_initialization(
        self, mock_get_parameter, mock_slack_app, mock_env_vars
    ):
        """Test that the Slack app is initialized correctly"""
        mock_get_parameter.side_effect = ["xoxb-test-token", "test-signing-secret"]
        mock_app_instance = Mock()
        mock_slack_app.return_value = mock_app_instance

        # Reset app to None to force recreation
        main.app = None

        # Test app creation
        app = main.get_slack_app()

        # Verify parameters were retrieved
        assert mock_get_parameter.call_count == 2
        mock_get_parameter.assert_any_call("/test/slack/bot-token")
        mock_get_parameter.assert_any_call("/test/slack/signing-secret")

        # Verify App was created with correct parameters
        mock_slack_app.assert_called_once_with(
            process_before_response=True,
            token="xoxb-test-token",
            signing_secret="test-signing-secret",
        )
        assert app == mock_app_instance

    @patch("main.get_parameter")
    @patch("main.get_bedrock_knowledge_base_response")
    @patch("main.SlackMarkdownConverter")
    def test_markdown_conversion(
        self, mock_converter_class, mock_kb_service, mock_get_parameter, mock_env_vars
    ):
        """Test that markdown conversion is applied"""
        # Setup mocks
        mock_get_parameter.side_effect = ["xoxb-test-token", "test-signing-secret"]
        mock_kb_service.return_value = {"output": {"text": "**Bold text**"}}

        mock_converter = Mock()
        mock_converter_class.return_value = mock_converter
        mock_converter.convert.return_value = "*Bold text*"  # Slack markdown

        mock_respond = Mock()
        mock_body = {"text": "test query"}

        main.process_command_request(mock_respond, mock_body)

        # Verify converter was used
        mock_converter_class.assert_called_once()
        mock_converter.convert.assert_called_once_with("**Bold text**")

        # Verify converted text is in response
        response_call = mock_respond.call_args[0][0]
        assert "*Bold text*" in response_call["blocks"][0]["text"]["text"]
