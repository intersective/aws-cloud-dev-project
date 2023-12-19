#!/bin/bash

# first you need to get access credentials
# aws configure

# our app is already built - we're using a prebuilt zap image
export APP_URI=ghcr.io/zaproxy/zaproxy:stable

# but we need to build our NGNIX proxy which will be used to route traffic to our app
# we will also use it to provide some basic authentication
NGNIX_URI=$(aws ecr create-repository --repository-name app --query 'repository.repositoryUri' --output text)
docker build -t $NGNIX_URI .
docker push $NGNIX_URI

sam deploy \
  --template-file stack.yml \
  --stack-name nginx-reverse-proxy \
  --resolve-s3 \
  --capabilities CAPABILITY_IAM \
  --profile zap \
  --parameter-overrides AppImageUrl=$APP_URI NginxImageUrl=$NGINX_URI
