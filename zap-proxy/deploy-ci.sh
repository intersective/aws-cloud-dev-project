#!/bin/bash

# Function to deploy a stack
deploy_stack() {
    TeamName=$1
    Client=$2
    SubDomainName=$3
    StackName=$4
    RootDomainName=$5

    sam deploy \
        --template-file stack.yml \
        --stack-name $StackName \
        --s3-bucket cybersec-deployment-files \
        --debug \
        --capabilities CAPABILITY_NAMED_IAM \
        --profile default \
        --region us-east-1 \
        --parameter-overrides "AppImageUrl=$APP_URI" "Client=$Client" "NginxImageUrl=$NGNIX_URI TeamName=$TeamName SubDomainName=$SubDomainName SSLCertificateArn=$CERTIFICATE_ARN RootDomainName=$RootDomainName"

    # Check the deployment status
    if [ $? -ne 0 ]; then
        echo "Error: Deployment failed for $StackName. Halting execution."
        exit 1
    fi
}

# Set NGINX_IMAGE_URI and other variables here
export NGNIX_URI=510645120987.dkr.ecr.us-east-1.amazonaws.com/nginx:latest
export CERTIFICATE_ARN=arn:aws:acm:us-east-1:510645120987:certificate/9e8615de-927e-427c-8e44-31e980de1de5
export APP_URI=510645120987.dkr.ecr.us-east-1.amazonaws.com/zaproxy:latest

TeamName="${TEAM_NAME:-team-ci}"
Client="${CLIENT:-client-ci}"
SubDomainName="$TeamName-$Client.cybersec.practeraco.de"
StackName="$TeamName-$Client"
RootDomainName="cybersec.practeraco.de"

deploy_stack "$TeamName" "$Client" "$SubDomainName" "$StackName" "$RootDomainName"