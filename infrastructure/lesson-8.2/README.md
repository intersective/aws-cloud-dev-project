# Lesson 7

### Setting up AWS Cognito for Authentication


Feel free to change `lessonEightTwoStack` as the stack name.


## Create
aws cloudformation package --template-file infrastructure/lesson-8.2/main.yml --output-template-file tmp/lesson-8.2.yml --s3-bucket pcloud-lessonsixs3-dev --s3-prefix deployment-packages 

aws cloudformation deploy --template-file tmp/lesson-8.2.yml --stack-name lessonEightTwoStack --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_IAM  --parameter-overrides UserEmail=rodney@practera.com

## Delete
aws cloudformation delete-stack --stack-name lessonEightTwoStack