import logging
import os
from typing import Any, Callable, Dict, Optional

from kb_service import get_bedrock_knowledge_base_response
from markdown_to_mrkdwn import SlackMarkdownConverter
from parameter_service import get_parameter
from slack_bolt import App

# Get environment variables with defaults for testing
bot_token_parameter: str = os.environ.get(
    "SLACK_BOT_TOKEN_PARAMETER", "/test/slack/bot-token"
)
signing_secret_parameter: str = os.environ.get(
    "SLACK_SIGNING_SECRET_PARAMETER", "/test/slack/signing-secret"
)
slack_slash_command: str = os.environ.get("SLACK_SLASH_COMMAND", "/test-llm")

# For testing, allow direct app assignment
app: Optional[App] = None


def get_slack_app() -> App:
    """Get or create Slack app with lazy parameter loading"""
    global app
    if app is None:
        bot_token = get_parameter(bot_token_parameter)
        signing_secret = get_parameter(signing_secret_parameter)
        app = App(
            process_before_response=True, token=bot_token, signing_secret=signing_secret
        )
    return app


def log_request(logger: Any, body: Dict[str, Any], next: Callable) -> Any:
    """Middleware function for logging requests"""
    logger.debug(body)
    return next()


def respond_to_slack_within_3_seconds(body: Dict[str, Any], ack: Callable) -> None:
    """Respond to Slack within 3 seconds to acknowledge command receipt"""
    if body.get("text") is None:
        ack(f":x: Usage: {slack_slash_command} (description here)")
    else:
        title = body["text"]
        ack(f"Accepted Task. Generating response... :hourglass_flowing_sand:")


def process_command_request(respond: Callable, body: Dict[str, Any]) -> None:
    """
    Receive the Slack Slash Command user query and proxy the query to Bedrock Knowledge base ReteriveandGenerate API
    and return the response to Slack to be presented in the users chat thread.
    """
    try:
        # Get the user query
        user_query: str = body["text"]
        logging.info(
            f"{slack_slash_command} - Responding to command: {slack_slash_command} - User Query: {user_query}"
        )

        kb_response = get_bedrock_knowledge_base_response(user_query)
        converter = SlackMarkdownConverter()
        response_text: str = converter.convert(kb_response["output"]["text"])
        respond(
            {
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"*{slack_slash_command}* - Response:\n\n{response_text}",
                        },
                    }
                ]
            }
        )

    except Exception as err:
        print(f"{slack_slash_command} - Error: {err}")
        respond(
            f"{slack_slash_command} - Sorry an error occurred. Please try again later. Error: {err}"
        )


def setup_app_handlers() -> App:
    """Setup app handlers and middleware"""
    slack_app = get_slack_app()
    slack_app.middleware(log_request)
    slack_app.command(slack_slash_command)(
        ack=respond_to_slack_within_3_seconds, lazy=[process_command_request]
    )
    return slack_app
