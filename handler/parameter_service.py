import json
from typing import Any, Dict, Union

import boto3


def get_parameter(parameter_name: str) -> str:
    ssm = boto3.client("ssm")
    try:
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
        # Parse the JSON string from the parameter
        parameter_value: str = response["Parameter"]["Value"]

        # Remove the JSON structure and extract just the value
        try:
            json_value: Dict[str, Any] = json.loads(parameter_value)
            # Get the first value from the dictionary
            value: Any = next(iter(json_value.values()))
            return str(value)
        except (json.JSONDecodeError, StopIteration):
            # If parsing fails or dictionary is empty, return the raw value
            return parameter_value

    except Exception as e:
        print(f"Error getting parameter {parameter_name}: {str(e)}")
        raise e
