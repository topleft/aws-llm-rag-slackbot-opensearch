import logging
import time
import os

from slack_bolt import App 
from slack_bolt.adapter.aws_lambda import SlackRequestHandler
from markdown_to_mrkdwn import SlackMarkdownConverter
from parameter_service import get_parameter
from kb_service import get_bedrock_knowledgebase_response

bot_token_parameter = os.environ["SLACK_BOT_TOKEN_PARAMETER"]
signing_secret_parameter = os.environ["SLACK_SIGNING_SECRET_PARAMETER"]
slack_slash_command = os.environ["SLACK_SLASH_COMMAND"]

# Retrieve the parameters
bot_token = get_parameter(bot_token_parameter)
signing_secret = get_parameter(signing_secret_parameter)

app = App(process_before_response=True, token=bot_token, signing_secret=signing_secret)


@app.middleware  # or app.use(log_request)
def log_request(logger, body, next):
    logger.debug(body)
    return next()


def respond_to_slack_within_3_seconds(body, ack):
    if body.get("text") is None:
        ack(f":x: Usage: {slack_slash_command} (description here)")
    else:
        title = body["text"]
        ack(f"Accepted Task. Generating response... :hourglass_flowing_sand:")


def process_command_request(respond, body):
    """
    Receive the Slack Slash Command user query and proxy the query to Bedrock Knowledge base ReteriveandGenerate API
    and return the response to Slack to be presented in the users chat thread.
    """
    try:
        # Get the user query
        user_query = body["text"]
        logging.info(
            f"{slack_slash_command} - Responding to command: {slack_slash_command} - User Query: {user_query}"
        )

        kb_response = get_bedrock_knowledgebase_response(user_query)
        converter = SlackMarkdownConverter()
        response_text = converter.convert(kb_response["output"]["text"])
        respond(
            {
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"*{slack_slash_command}* - Response:\n\n{response_text}"
                        }
                    }
                ]
            }
        )

    except Exception as err:
        print(f"{slack_slash_command} - Error: {err}")
        respond(
            f"{slack_slash_command} - Sorry an error occurred. Please try again later. Error: {err}"
        )


app.command(slack_slash_command)(
    ack=respond_to_slack_within_3_seconds, lazy=[process_command_request]
)

SlackRequestHandler.clear_all_log_handlers()
logging.basicConfig(format="%(asctime)s %(message)s", level=logging.DEBUG)


def handler(event, context):
    slack_handler = SlackRequestHandler(app=app)
    return slack_handler.handle(event, context)
