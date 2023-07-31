# Lesson 7

### Host the Documentation using AWS Services


Feel free to change `lessonEightStack` as the stack name.


## Get Exports

#### For BucketName parameter
export BucketName=$(aws cloudformation list-exports --query "Exports[?Name==\`pcloud-S3MainBucketRef-dev\`].Value" --no-paginate --output text)

#### For S3BucketRegionalDomainName parameter
export S3BucketRegionalDomainName=$(aws cloudformation list-exports --query "Exports[?Name==\`pcloud-S3MainBucketRegionalDomainName-dev\`].Value" --no-paginate --output text)


## Create
aws cloudformation package --template-file infrastructure/lesson-8.1/main.yml --output-template-file tmp/lesson-8.1.yml --s3-bucket pcloud-lessonsixs3-dev --s3-prefix deployment-packages 

aws cloudformation deploy --template-file tmp/lesson-8.1.yml --stack-name lessonEightStack --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_IAM  --parameter-overrides BucketName=$BucketName S3BucketRegionalDomainName=$S3BucketRegionalDomainName


### Copy to S3
aws s3 cp docs/build s3://pcloud-lessonsixs3-dev/doc/ --recursive

## Delete
aws cloudformation delete-stack --stack-name lessonEightStack