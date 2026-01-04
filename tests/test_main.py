import json
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, Mock, patch

import pytest

# Add handler directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "handler"))

# Now safe to import main
import main


class TestMainHandler:
    """Test main Lambda handler function"""

    @patch("slack_service.get_parameter")
    @patch("slack_service.App")
    @patch("main.SlackRequestHandler")
    def test_lambda_handler(
        self, mock_slack_handler, mock_app, mock_get_parameter, mock_env_vars
    ):
        """Test Lambda handler integration"""
        # Mock get_parameter to return test credentials
        mock_get_parameter.side_effect = ["xoxb-test-token", "test-signing-secret"]

        # Create a real mock app to avoid Slack API calls
        mock_app_instance = Mock()
        mock_app_instance.command.return_value = Mock()
        mock_app_instance.middleware = Mock()
        mock_app.return_value = mock_app_instance

        mock_handler_instance = Mock()
        mock_slack_handler.return_value = mock_handler_instance
        mock_handler_instance.handle.return_value = {"statusCode": 200}

        # Test event and context
        test_event = {"body": "test-body"}
        test_context = {"aws_request_id": "test-123"}

        result = main.handler(test_event, test_context)

        # Verify SlackRequestHandler was created with app
        mock_slack_handler.assert_called_once_with(app=mock_app_instance)

        # Verify handler was called correctly
        mock_handler_instance.handle.assert_called_once_with(test_event, test_context)
        assert result == {"statusCode": 200}
