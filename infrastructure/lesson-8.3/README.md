# Lesson 7

### Using Cognito with CloudFront + Lamba@Edge


Feel free to change `lessonEightThreeStack` as the stack name.

## Get Exports

#### For DocsCloudFrontOriginAccessIdentity parameter
export DocsCloudFrontOriginAccessIdentity=$(aws cloudformation list-exports --query "Exports[?Name==\`pcloud-DocsCloudFrontOriginAccessIdentity-dev\`].Value" --no-paginate --output text)

## Create
aws cloudformation package --template-file infrastructure/lesson-8.3/main.yml --output-template-file tmp/lesson-8.3.yml --s3-bucket pcloud-lessonsixs3-dev --s3-prefix deployment-packages 

aws cloudformation deploy --template-file tmp/lesson-8.3.yml --stack-name lessonEightThreeStack --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_IAM  --parameter-overrides AuthStackName=pcloud-sandbox DocsCloudFrontOriginAccessIdentity=$DocsCloudFrontOriginAccessIdentity

## Delete
aws cloudformation delete-stack --stack-name lessonEightThreeStack