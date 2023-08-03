#!/bin/bash

set -e

# This script takes the following command-line args:
# -n <unique name> 


export AWS_PAGER="" # disable output that needs to exit on AWS cli commands

# Parse command-line arguments; removed region parameter
while getopts ":n:" opt; do
    case ${opt} in
    n) LAMBDA_NAME=$OPTARG ;;
    \?)
        echo "Usage: cmd [-n name]"
        exit 1
        ;;
    esac
done

if [[ -z "${LAMBDA_NAME}" ]]; then
    echo "Lambda name is required."
    exit 1
fi

function_names=$(aws lambda list-functions | jq --arg name "$LAMBDA_NAME" -r '.Functions[] | select(.FunctionName | contains($name)) | .FunctionName')
for function_name in $function_names; do
  echo "Deleting Lambda function: $function_name"
  aws lambda delete-function --function-name "$function_name"
done