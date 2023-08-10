#!/bin/bash

set -e

# This script takes the following command-line args:
# -e <email> REQUIRED
# -n <unique name> optional
# -r <region> optional
# -s <step number> optional

export AWS_PAGER="" # disable output that needs to exit on AWS cli commands

# Define steps
step_start_repo=1
step_create_bucket=2
step_lambda_dynamo_api=3
step_docusaurus=4
step_cognito_auth=5
step_cdn_lambda=6

# Parse command-line arguments; removed region parameter
while getopts ":n:e:a:c:i:s:" opt; do
    case ${opt} in
    n) NAME=$OPTARG ;;
    e) EMAIL=$OPTARG ;;
    a) ACTION=$OPTARG ;;
    c) COUNT=$OPTARG ;;
    i) INDEX=$OPTARG ;;
    s) STEP=$OPTARG ;;
    \?)
        echo "Usage: cmd [-n name] [-e email] [-a action [create | delete]] [-c count] [-i index (integer)]"
        exit 1
        ;;
    esac
done

# Default values for name and region
: ${NAME:=$(uuidgen)}
: ${REGION:=us-east-1}
: ${INDEX:=1}
: ${STEP:=1}

# Verify that email is set
if [[ -z "${EMAIL}" ]]; then
    echo "Email is required."
    exit 1
fi

if [[ -z "${ACTION}" ]]; then
    echo "Action is required."
    exit 1
fi

if [[ -z "${COUNT}" ]]; then
    echo "Count is required."
    exit 1
fi

if [[ ! "$COUNT" =~ ^[0-9]+$ || "$COUNT" -lt 1 ]]; then
    echo "Invalid value for COUNT. It must be an integer greater than 1." >&2
    exit 1
fi

if [[ "$ACTION" != "create" && "$ACTION" != "delete" ]]; then
    echo "Invalid action: $ACTION. Only 'create' or 'delete' are allowed."
    exit 1
fi

create() {
    if [ -z "$1" ]; then
        echo "single parameter is required"
        exit 1
    fi

    RESOURCE_NAME="$NAME""-""$1"
    WORKDIR="$HOME/$RESOURCE_NAME"

    echo "Creating "$RESOURCE_NAME" .."

    if [[ $STEP -le $step_start_repo ]]; then

        # clone github repo into codecommit
        cd $HOME
        git clone https://github.com/intersective/aws-cloud-dev-project.git $RESOURCE_NAME
        cd $RESOURCE_NAME
        aws codecommit create-repository --repository-name $RESOURCE_NAME-repository --repository-description "repository-description"
        git remote set-url origin codecommit::$REGION://$RESOURCE_NAME-repository
        git push

        git config --global user.email "$EMAIL"
        git config --global user.name "$RESOURCE_NAME"

        git checkout -b test/"$RESOURCE_NAME"
        date | cat >>.version
        git status
        git add .
        git commit -m "Added version file"
        git push --set-upstream origin test/"$RESOURCE_NAME"

        if [[ $? -ne 0 ]]; then
            echo "Error in create $step_start_repo"
            exit 1
        fi
    fi

    if [[ $STEP -le $step_create_bucket ]]; then
        if [ "$(pwd)" != "$WORKDIR" ]; then
            cd "$WORKDIR"
        fi
        # build api
        rm -rf node_modules
        sudo npm install -g typescript
        npm install --omit=dev
        npm i --save-dev @types/node
        npm run build --omit=dev

        # zip build output
        mkdir tmp
        zip -r tmp/api.zip dist/ node_modules/

        # create the S3 Bucket; LocationConstraint default is us-east-1;
        aws s3api create-bucket --bucket $RESOURCE_NAME-s3-bucket --region $REGION

        # copy files to s3
        aws s3 cp tmp/api.zip s3://$RESOURCE_NAME-s3-bucket/deployment-packages/
        rm tmp/api.zip # delete cloudshell storage issue;

        if [[ $? -ne 0 ]]; then
            echo "Error in create $step_create_bucket"
            exit 1
        fi

    fi

    if [[ $STEP -le $step_lambda_dynamo_api ]]; then
        if [ "$(pwd)" != "$WORKDIR" ]; then
            cd "$WORKDIR"
        fi
        cp -r node_modules dist/
        aws cloudformation package --template-file devops/basic-api-cfn.yml --output-template-file tmp/api-pkg.yml --s3-bucket $RESOURCE_NAME-s3-bucket --s3-prefix deployment-packages

        aws cloudformation deploy --template-file tmp/api-pkg.yml --stack-name $RESOURCE_NAME-lambda-stack --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_IAM --parameter-overrides S3BUCKET=$RESOURCE_NAME-s3-bucket Email=$EMAIL

        rm -rf dist/node_modules/ # delete cloudshell storage issue;
        rm -rf node_modules/      # node_modules won't be used in proceeding lessons

        if [[ $? -ne 0 ]]; then
            echo "Error in create $step_lambda_dynamo_api"
            exit 1
        fi

    fi

    if [[ $STEP -le $step_docusaurus ]]; then
        if [ "$(pwd)" != "$WORKDIR" ]; then
            cd "$WORKDIR"
        fi
        # package
        aws cloudformation package --template-file devops/basic-docs-cfn.yml --output-template-file tmp/docs-pkg.yml --s3-bucket $RESOURCE_NAME-s3-bucket --s3-prefix deployment-packages

        # deploy
        aws cloudformation deploy --template-file tmp/docs-pkg.yml --stack-name $RESOURCE_NAME-docs-stack --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_IAM --parameter-overrides StackName=$RESOURCE_NAME-docs-stack S3BUCKET=$RESOURCE_NAME-s3-bucket

        # copy docusaurus files to s3
        aws s3 cp docs/build s3://$RESOURCE_NAME-docs-stack-docs/ --recursive

        if [[ $? -ne 0 ]]; then
            echo "Error in create $step_docusaurus"
            exit 1
        fi

    fi

    if [[ $STEP -le $step_cognito_auth ]]; then
        if [ "$(pwd)" != "$WORKDIR" ]; then
            cd "$WORKDIR"
        fi

        # package
        aws cloudformation package --template-file devops/prod-auth-cfn.yml --output-template-file tmp/auth-pkg.yml --s3-bucket $RESOURCE_NAME-s3-bucket --s3-prefix deployment-packages

        # deploy
        aws cloudformation deploy --template-file tmp/auth-pkg.yml --stack-name $RESOURCE_NAME-auth-stack --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_IAM --parameter-overrides UserEmail=$EMAIL StackName=$RESOURCE_NAME-auth-stack

        if [[ $? -ne 0 ]]; then
            echo "Error in delete $step_cognito_auth"
            exit 1
        fi

    fi

    if [[ $STEP -le $step_cdn_lambda ]]; then
        if [ "$(pwd)" != "$WORKDIR" ]; then
            cd "$WORKDIR"
        fi

        # package
        aws cloudformation package --template-file devops/prod-docs-cfn.yml --output-template-file tmp/docs-pkg.yml --s3-bucket $RESOURCE_NAME-s3-bucket --s3-prefix deployment-packages

        # deploy
        aws cloudformation deploy --template-file tmp/docs-pkg.yml --stack-name $RESOURCE_NAME-docs-cdn-lambdaedge-stack --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_IAM --parameter-overrides StackName=$RESOURCE_NAME-docs-cdn-lambdaedge-stack AuthStackName=$RESOURCE_NAME-auth-stack

        # copy files
        aws s3 cp docs/build s3://$RESOURCE_NAME-docs-cdn-lambdaedge-stack-app/ --recursive

    fi

    if [[ $STEP != 1 ]]; then
        STEP=1
        echo "Return step to: $STEP"
    fi

    # delete previous repo;
    cd $HOME
    rm -rf $RESOURCE_NAME
}

delete() {
    if [ -z "$1" ]; then
        echo "single parameter is required"
        exit 1
    fi

    RESOURCE_NAME="$NAME""-""$1"

    echo "Deleting "$RESOURCE_NAME" .."

    if [[ $STEP -le $step_start_repo ]]; then
        aws codecommit delete-repository --repository-name $RESOURCE_NAME-repository
        if [[ $? -ne 0 ]]; then
            echo "Error in delete $step_start_repo"
            exit 1
        fi
    fi

    if [[ $STEP -le $step_create_bucket ]]; then
        # empty bucket
        aws s3 rm s3://$RESOURCE_NAME-s3-bucket --recursive

        # delete
        aws s3 rb s3://$RESOURCE_NAME-s3-bucket

        if [[ $? -ne 0 ]]; then
            echo "Error in delete $step_create_bucket"
            exit 1
        fi

    fi

    if [[ $STEP -le $step_lambda_dynamo_api ]]; then
        aws cloudformation delete-stack --stack-name $RESOURCE_NAME-lambda-stack
        echo "Waiting for $RESOURCE_NAME-lambda-stack to be deleted . . ."
        aws cloudformation wait stack-delete-complete --stack-name $RESOURCE_NAME-lambda-stack

        if [[ $? -ne 0 ]]; then
            echo "Error in delete $step_lambda_dynamo_api"
            exit 1
        fi
    fi

    if [[ $STEP -le $step_docusaurus ]]; then

        # list all versions
        object_versions=$(aws s3api list-object-versions --bucket $RESOURCE_NAME-docs-stack-docs --output json)
        object_versions_base64=$(echo "$object_versions" | jq -r '.Versions[] | @base64')

        for item in $object_versions_base64; do
            # Decode the base64 item to get the required information
            version_id=$(echo "$item" | base64 --decode | jq -r '.VersionId')
            object_key=$(echo "$item" | base64 --decode | jq -r '.Key')

            # Delete the object version
            aws s3api delete-object --bucket $RESOURCE_NAME-docs-stack-docs --key "$object_key" --version-id $version_id
        done

        # empty bucket
        aws s3 rm s3://$RESOURCE_NAME-docs-stack-docs --recursive

        delete_marker_list=$(aws s3api list-object-versions --bucket $RESOURCE_NAME-docs-stack-docs --query 'DeleteMarkers[*].{VersionId:VersionId, Key:Key}' --output json)

        # Loop through the DeleteMarkers
        for item in $(echo "$delete_marker_list" | jq -r '.[] | @base64'); do
            version_id=$(echo "$item" | base64 --decode | jq -r '.VersionId')
            object_key=$(echo "$item" | base64 --decode | jq -r '.Key')

            aws s3api delete-object --bucket $RESOURCE_NAME-docs-stack-docs --key "$object_key" --version-id $version_id

            echo "Deleted object with Key: $object_key and VersionId: $version_id"
        done

        aws cloudformation delete-stack --stack-name $RESOURCE_NAME-docs-stack
        echo "Waiting for $RESOURCE_NAME-docs-stack to be deleted . . ."
        aws cloudformation wait stack-delete-complete --stack-name $RESOURCE_NAME-docs-stack

        if [[ $? -ne 0 ]]; then
            echo "Error in delete $step_docusaurus"
            exit 1
        fi
    fi

    if [[ $STEP -le $step_cdn_lambda ]]; then
        # list all versions
        object_versions=$(aws s3api list-object-versions --bucket $RESOURCE_NAME-docs-cdn-lambdaedge-stack-app --output json)
        object_versions_base64=$(echo "$object_versions" | jq -r '.Versions[] | @base64')

        for item in $object_versions_base64; do
            # Decode the base64 item to get the required information
            version_id=$(echo "$item" | base64 --decode | jq -r '.VersionId')
            object_key=$(echo "$item" | base64 --decode | jq -r '.Key')

            # Delete the object version
            aws s3api delete-object --bucket $RESOURCE_NAME-docs-cdn-lambdaedge-stack-app --key "$object_key" --version-id $version_id
        done

        # empty bucket
        aws s3 rm s3://$RESOURCE_NAME-docs-cdn-lambdaedge-stack-app --recursive

        delete_marker_list=$(aws s3api list-object-versions --bucket $RESOURCE_NAME-docs-cdn-lambdaedge-stack-app --query 'DeleteMarkers[*].{VersionId:VersionId, Key:Key}' --output json)

        # Loop through the DeleteMarkers
        for item in $(echo "$delete_marker_list" | jq -r '.[] | @base64'); do
            version_id=$(echo "$item" | base64 --decode | jq -r '.VersionId')
            object_key=$(echo "$item" | base64 --decode | jq -r '.Key')

            aws s3api delete-object --bucket $RESOURCE_NAME-docs-cdn-lambdaedge-stack-app --key "$object_key" --version-id $version_id

            echo "Deleted object with Key: $object_key and VersionId: $version_id"
        done

        # lambda functions in this stack won't be deleted
        # because it is replicated;
        # according to this official docs [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-delete-replicas.html]
        # Replicas will be automatically deleted after some few hours
        # Then we manually delete the functions in Lambda AWS Console page
        aws cloudformation delete-stack --stack-name $RESOURCE_NAME-docs-cdn-lambdaedge-stack
        echo "Waiting for $RESOURCE_NAME-docs-cdn-lambdaedge-stack to be deleted . . ."

        get_stack_status() {
            aws cloudformation describe-stacks --stack-name "$1" | jq -r '.Stacks[0].StackStatus'
        }

        STACK_STATUS=$(get_stack_status "$RESOURCE_NAME-docs-cdn-lambdaedge-stack")

        while [ "$STACK_STATUS" != "DELETE_FAILED" ]; do
            sleep 60 # Sleep for 1 minute (60 seconds)
            STACK_STATUS=$(get_stack_status "$RESOURCE_NAME-docs-cdn-lambdaedge-stack")
        done

        echo "Status $RESOURCE_NAME-docs-cdn-lambdaedge-stack is DELETE_FAILED now."

        # above will fail; delete stack and retain resources

        # delete lambda protection stack
        LAMBDA_STACK_ID=$(aws cloudformation describe-stack-resources --stack-name $RESOURCE_NAME-docs-cdn-lambdaedge-stack --query 'StackResources[?ResourceType==`AWS::CloudFormation::Stack`].PhysicalResourceId' --output text)
        LAMBDA_STACK_NAME=$(aws cloudformation describe-stacks --stack-name $LAMBDA_STACK_ID | jq -r '.Stacks[0].StackName')
        aws cloudformation delete-stack --stack-name $LAMBDA_STACK_NAME --retain-resources CheckAuthHandler HttpHeadersHandler ParseAuthHandler RefreshAuthHandler SignOutHandler
        echo "Waiting for $LAMBDA_STACK_NAME to be deleted . . ."
        aws cloudformation wait stack-delete-complete --stack-name $LAMBDA_STACK_NAME

        # delete main stack
        aws cloudformation delete-stack --stack-name $RESOURCE_NAME-docs-cdn-lambdaedge-stack
        echo "Waiting for $RESOURCE_NAME-docs-cdn-lambdaedge-stack to be deleted . . ."
        aws cloudformation wait stack-delete-complete --stack-name $RESOURCE_NAME-docs-cdn-lambdaedge-stack

        if [[ $? -ne 0 ]]; then
            echo "Error in delete $step_docusaurus"
            exit 1
        fi
    fi

    if [[ $STEP -le $step_cognito_auth ]]; then
        aws cloudformation delete-stack --stack-name $RESOURCE_NAME-auth-stack
        echo "Waiting for $RESOURCE_NAME-auth-stack to be deleted . . ."
        aws cloudformation wait stack-delete-complete --stack-name $RESOURCE_NAME-auth-stack

    fi
}

main() {
    if [[ "$ACTION" == "create" ]]; then
        for ((i = $INDEX; i <= COUNT; i++)); do
            echo "$i"
            create $i
        done
    fi

    if [[ "$ACTION" == "delete" ]]; then
        for ((i = $INDEX; i <= COUNT; i++)); do
            delete $i
        done
    fi
}

main
