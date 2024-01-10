#!/bin/bash

# first you need to get access credentials
# aws configure

# our app is already built - we're using a prebuilt zap image
export APP_URI=ghcr.io/zaproxy/zaproxy:stable

# but we need to build our NGNIX proxy which will be used to route traffic to our app
# we will also use it to provide some basic authentication
# NGNIX_URI=$(aws ecr create-repository --repository-name app --query 'repository.repositoryUri' --output text)
# docker build -t $NGNIX_URI .
# docker push $NGNIX_URI


export NGNIX_URI=510645120987.dkr.ecr.us-east-1.amazonaws.com/nginx


sam deploy \
  --template-file stack.yml \
  --stack-name team-1-wbla-practeraco-de \
  --region us-east-1 \
  --resolve-s3 \
  --capabilities CAPABILITY_IAM \
  --debug \
  --parameter-overrides "AppImageUrl=$APP_URI" "NginxImageUrl=$NGNIX_URI" "SubDomainName=team-1-wbla.cybersec.practeraco.de"
