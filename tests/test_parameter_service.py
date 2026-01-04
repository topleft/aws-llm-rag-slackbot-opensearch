import json
import sys
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

# Add handler directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "handler"))
from parameter_service import get_parameter


class TestParameterService:
    """Test parameter service functionality"""

    def test_get_parameter_simple_string(self, mock_ssm_client):
        """Test getting a simple string parameter"""
        result = get_parameter("/test/slack/bot-token")
        assert result == "xoxb-test-token"

    def test_get_parameter_json_value(self, mock_ssm_client):
        """Test getting a parameter with JSON value"""
        # Add a JSON parameter
        mock_ssm_client.put_parameter(
            Name="/test/json-param", Value='{"key": "json-value"}', Type="SecureString"
        )

        result = get_parameter("/test/json-param")
        assert result == "json-value"

    def test_get_parameter_invalid_json_fallback(self, mock_ssm_client):
        """Test fallback to raw value when JSON parsing fails"""
        # Add an invalid JSON parameter
        mock_ssm_client.put_parameter(
            Name="/test/invalid-json", Value="not-json-value", Type="String"
        )

        result = get_parameter("/test/invalid-json")
        assert result == "not-json-value"

    @patch("boto3.client")
    def test_get_parameter_ssm_error(self, mock_boto_client):
        """Test error handling when SSM fails"""
        mock_ssm = Mock()
        mock_boto_client.return_value = mock_ssm
        mock_ssm.get_parameter.side_effect = Exception("SSM Error")

        with pytest.raises(Exception) as exc_info:
            get_parameter("/test/nonexistent")

        assert "SSM Error" in str(exc_info.value)

    def test_get_parameter_empty_json(self, mock_ssm_client):
        """Test handling of empty JSON object"""
        mock_ssm_client.put_parameter(
            Name="/test/empty-json", Value="{}", Type="SecureString"
        )

        result = get_parameter("/test/empty-json")
        assert result == "{}"  # Should fallback to raw value
