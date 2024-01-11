#!/bin/bash
## Note: One time run only. Need to export VPC stack for reuse.

set -eo pipefail

STACK_NAME="nginx-reverse-proxy-VpcStack-E82C9WU64D0Q"

PUBLIC_SUBNETS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs" | jq -r '.[] | select(.OutputKey == "PublicSubnetIds") | .OutputValue')
VPC_ID=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs" | jq -r '.[] | select(.OutputKey == "VpcId") | .OutputValue')


EXPORT_STACK_NAME="cybersecurity-export-vpc"

aws cloudformation deploy --template-file export-vpc.yml --stack-name $EXPORT_STACK_NAME --parameter-overrides PublicSubnetIds=$PUBLIC_SUBNETS VpcId=$VPC_ID
