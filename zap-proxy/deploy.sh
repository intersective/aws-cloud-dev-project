#!/bin/bash

# first you need to get access credentials
# aws configure

# our app is already built - we're using a prebuilt zap image


# but we need to build our NGNIX proxy which will be used to route traffic to our app
# we will also use it to provide some basic authentication


## NGINIX IMAGE AND PUSH TO ECR:
# NGNIX_URI=$(aws ecr create-repository --repository-name myapp --query 'repository.repositoryUri' --output text --region us-east-1)
# docker build -t $NGNIX_URI .
# docker push $NGNIX_URI


#########################PCLOUD-SANDBOX##############################################
# This is for Pcloud - Sandbox used.
# export CERTIFICATE_ARN=arn:aws:acm:us-east-1:320980967765:certificate/380362bf-8908-4f05-90b5-9049f3cbca97
# export NGNIX_URI=320980967765.dkr.ecr.us-east-1.amazonaws.com/app:latest
# export APP_URI=ghcr.io/zaproxy/zaproxy:stable

# TeamName=team-1
# Client=wbla
# SubDomainName=$TeamName-$Client.pcloud.practeraco.de
# StackName=$TeamName-$Client
# RootDomainName=pcloud.practeraco.de
# sam deploy \
#   --template-file stack.yml \
#   --stack-name $StackName \
#   --s3-bucket  sam-s3-bucket-pcloud \
#   --debug \
#   --profile pcloud-sandbox \
#   --parameter-overrides "AppImageUrl=$APP_URI" "NginxImageUrl=$NGNIX_URI TeamName=$TeamName SubDomainName=$SubDomainName SSLCertificateArn=$CERTIFICATE_ARN RootDomainName=$RootDomainName"


#########################CYBER-SANDBOX##############################################
# This is for Cyber - Sandbox used.
export NGNIX_URI=510645120987.dkr.ecr.us-east-1.amazonaws.com/nginx
export CERTIFICATE_ARN=arn:aws:acm:us-east-1:510645120987:certificate/9e8615de-927e-427c-8e44-31e980de1de5
export APP_URI=ghcr.io/zaproxy/zaproxy:stable

TeamName=team-1
Client=wbla
SubDomainName=$TeamName-$Client.cybersec.practeraco.de
StackName=$TeamName-$Client
RootDomainName=cybersec.practeraco.de
sam deploy \
  --template-file stack.yml \
  --stack-name $StackName \
  --s3-bucket  cybersec-deployment-files \
  --debug \
  --profile cyber-sandbox \
  --parameter-overrides "AppImageUrl=$APP_URI" "NginxImageUrl=$NGNIX_URI TeamName=$TeamName SubDomainName=$SubDomainName SSLCertificateArn=$CERTIFICATE_ARN RootDomainName=$RootDomainName"

  