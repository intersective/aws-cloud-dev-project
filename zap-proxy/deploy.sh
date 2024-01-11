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
export CERTIFICATE_ARN=arn:aws:acm:us-east-1:510645120987:certificate/9e8615de-927e-427c-8e44-31e980de1de5

sam deploy \
  --template-file stack.yml \
  --stack-name team-1-skillsbuild-cybersec-practeraco-de \
  --debug \
  --parameter-overrides "AppImageUrl=$APP_URI" "NginxImageUrl=$NGNIX_URI TeamName=team-1 SubDomainName=team-1-skillsbuild.cybersec.practeraco.de SSLCertificateArn=$CERTIFICATE_ARN"
