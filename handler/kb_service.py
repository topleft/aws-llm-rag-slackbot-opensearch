import logging
import os
from typing import Any, Dict

import boto3

# Get the expected slack and AWS account params to local vars.
KNOWLEDGEBASE_ID: str = os.environ["KNOWLEDGEBASE_ID"]
INFERENCE_PROFILE_ID: str = os.environ["INFERENCE_PROFILE_ID"]
AWS_REGION: str = os.environ["AWS_REGION"]


def get_bedrock_knowledge_base_response(user_query: str) -> Dict[str, Any]:
    """
    Get and return the Bedrock Knowledge Base ReteriveAndGenerate response.
    Do all init tasks here instead of globally as initial invocation of this lambda
    provides Slack required ack in 3 sec. It doesn't trigger any bedrock functions and is
    time sensitive.
    """

    # Initialise the bedrock-runtime client (in default / running region).
    client = boto3.client(service_name="bedrock-agent-runtime", region_name=AWS_REGION)

    # Create the RetrieveAndGenerateCommand input with the user query.
    input_data: Dict[str, str] = {"text": user_query}

    config: Dict[str, Any] = {
        "type": "KNOWLEDGE_BASE",
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": KNOWLEDGEBASE_ID,
            "modelArn": INFERENCE_PROFILE_ID,
        },
    }

    response = client.retrieve_and_generate(
        input=input_data, retrieveAndGenerateConfiguration=config
    )
    logging.info(f"Bedrock Knowledge Base Response: {response}")
    return response
