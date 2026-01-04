import logging
from typing import Any, Dict

from slack_bolt.adapter.aws_lambda import SlackRequestHandler
from slack_service import setup_app_handlers

# Configure logging
SlackRequestHandler.clear_all_log_handlers()
logging.basicConfig(format="%(asctime)s %(message)s", level=logging.DEBUG)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler for Slack bot requests"""
    slack_app = setup_app_handlers()
    slack_handler = SlackRequestHandler(app=slack_app)
    return slack_handler.handle(event, context)
