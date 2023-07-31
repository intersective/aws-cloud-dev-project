# Lesson 6

### S3 Bucket creation


Feel free to change `lessonSixS3Stack` as the stack name and `BucketName` parameter value for your bucket name.

## Create
aws cloudformation create-stack --stack-name lessonSixS3Stack --template-body file://infrastructure/lesson-6/main.yml --parameters ParameterKey=BucketName,ParameterValue=lessonsixs3

## Delete
aws cloudformation delete-stack --stack-name lessonSixS3Stack