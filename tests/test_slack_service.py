import json
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, Mock, patch

import pytest

# Add handler directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "handler"))

# Mock Slack AsyncApp before importing slack_service
with patch("slack_bolt.async_app.AsyncApp") as mock_slack_app:
    mock_app_instance = Mock()
    mock_slack_app.return_value = mock_app_instance
    # Now safe to import slack_service
    import slack_service  # type: ignore


class TestSlackService:
    """Test Slack service functionality"""

    @patch("slack_service.get_bedrock_knowledge_base_response")
    def test_process_command_request_success(
        self, mock_kb_service, mock_env_vars, mock_bedrock_response
    ):
        """Test successful command processing"""
        mock_kb_service.return_value = mock_bedrock_response

        mock_respond = Mock()
        mock_body = {"text": "test query"}

        # Test the function
        slack_service.process_command_request(mock_respond, mock_body)

        # Verify knowledge base was called
        mock_kb_service.assert_called_once_with("test query")

        # Verify response was sent to Slack
        mock_respond.assert_called_once()
        call_args = mock_respond.call_args[0][0]
        assert "blocks" in call_args
        assert "section" in call_args["blocks"][0]["type"]
        assert "mrkdwn" in call_args["blocks"][0]["text"]["type"]
        assert "Response:" in call_args["blocks"][0]["text"]["text"]

    @patch("slack_service.get_bedrock_knowledge_base_response")
    def test_process_command_request_kb_error(self, mock_kb_service, mock_env_vars):
        """Test command processing with knowledge base error"""
        mock_kb_service.side_effect = Exception("KB Error")

        mock_respond = Mock()
        mock_body = {"text": "test query"}

        # Test the function
        slack_service.process_command_request(mock_respond, mock_body)

        # Verify error response was sent to Slack
        mock_respond.assert_called_once()
        call_args = mock_respond.call_args[0][0]
        assert "Sorry an error occurred" in call_args
        assert "KB Error" in call_args

    def test_respond_to_slack_within_3_seconds_with_text(self, mock_env_vars):
        """Test acknowledgment when text is provided"""
        mock_ack = Mock()
        mock_body = {"text": "test query"}

        slack_service.respond_to_slack_within_3_seconds(mock_body, mock_ack)

        mock_ack.assert_called_once_with(
            'Accepted Task.\n\n"test query"\n\nGenerating response... :hourglass_flowing_sand:'
        )

    def test_respond_to_slack_within_3_seconds_no_text(self, mock_env_vars):
        """Test acknowledgment when no text is provided"""
        mock_ack = Mock()
        mock_body = {}

        slack_service.respond_to_slack_within_3_seconds(mock_body, mock_ack)

        mock_ack.assert_called_once_with(":x: Usage: /test-llm <your question here>")

    @patch("slack_service.AsyncApp")  # Patch where it's used, not where it's imported
    async def test_app_initialization(self, mock_slack_app, mock_env_vars):
        """Test that the Slack app is initialized correctly"""
        mock_app_instance = Mock()
        mock_slack_app.return_value = mock_app_instance

        # Reset app to None to force recreation
        slack_service.app = None

        # Test app creation
        app = await slack_service.get_slack_app()

        # Verify AsyncApp was created with correct parameters from environment variables
        mock_slack_app.assert_called_once_with(
            process_before_response=True,
            token="test-slack-bot-token",  # From env defaults
            signing_secret="test-slack-signing-secret",  # From env defaults
        )
        assert app == mock_app_instance

    def test_log_request(self, mock_env_vars):
        """Test request logging middleware"""
        mock_logger = Mock()
        mock_body = {"test": "data"}
        mock_next = Mock(return_value="next_result")

        result = slack_service.log_request(mock_logger, mock_body, mock_next)

        # Verify logger was called
        mock_logger.debug.assert_called_once_with(mock_body)

        # Verify next function was called
        mock_next.assert_called_once()

        # Verify result is returned
        assert result == "next_result"

    @patch("slack_service.get_slack_app")
    def test_setup_app_handlers(self, mock_get_app, mock_env_vars):
        """Test app handlers setup"""
        mock_app = Mock()
        mock_get_app.return_value = mock_app

        result = slack_service.setup_app_handlers()

        # Verify app was retrieved
        mock_get_app.assert_called_once()

        # Verify middleware was added
        mock_app.middleware.assert_called_once_with(slack_service.log_request)

        # Verify command was registered
        mock_app.command.assert_called_once_with("/test-llm")

        # Verify the result is the app
        assert result == mock_app

    def test_markdown_conversion(self, mock_env_vars):
        """Test markdown to Slack mrkdwn conversion"""
        # Test data with markdown
        mock_kb_response = {
            "output": {
                "text": "Here is a **bold** text and some `code` example:\n\n```python\nprint('hello')\n```"
            }
        }

        mock_respond = Mock()
        mock_body = {"text": "test query"}

        with patch("slack_service.get_bedrock_knowledge_base_response") as mock_kb:
            mock_kb.return_value = mock_kb_response

            slack_service.process_command_request(mock_respond, mock_body)

            # Verify the response contains Slack formatting
            mock_respond.assert_called_once()
            call_args = mock_respond.call_args[0][0]
            response_text = call_args["blocks"][0]["text"]["text"]

            # Should contain Slack markdown formatting
            assert "*bold*" in response_text  # Bold formatting converted
            assert "`code`" in response_text  # Code formatting preserved
