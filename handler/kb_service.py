import os
import boto3
import logging

# Get the expected slack and AWS account params to local vars. 
KNOWLEDGEBASE_ID = os.environ['KNOWLEDGEBASE_ID'] 
INFERENCE_PROFILE_ID = os.environ['INFERENCE_PROFILE_ID']
AWS_REGION = os.environ['AWS_REGION']


def get_bedrock_knowledgebase_response(user_query):
  '''
    Get and return the Bedrock Knowledge Base ReteriveAndGenerate response.
    Do all init tasks here instead of globally as initial invocation of this lambda
    provides Slack required ack in 3 sec. It doesn't trigger any bedrock functions and is 
    time sensitive. 
  '''

  # Initialise the bedrock-runtime client (in default / running region).
  client = boto3.client(
    service_name='bedrock-agent-runtime',
    region_name=AWS_REGION
  )

  #Create the RetrieveAndGenerateCommand input with the user query.
  input =  { 
      "text": user_query
    }

  config = {
    "type" : "KNOWLEDGE_BASE",
    "knowledgeBaseConfiguration": {
        "knowledgeBaseId": KNOWLEDGEBASE_ID,
        "modelArn": INFERENCE_PROFILE_ID
   }
  }

  response = client.retrieve_and_generate(
    input=input, retrieveAndGenerateConfiguration=config
  )
  logging.info(f"Bedrock Knowledge Base Response: {response}")
  return response
