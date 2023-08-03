Documentation for the shell script:

# Shell Script: AWS Cloud Dev Project Automation

## Description
This shell script `auto-test.sh` automates the process of creating and deleting resources for an AWS Cloud Development project. It uses various AWS services like CodeCommit, S3, CloudFormation, and Lambda.

## Prerequisites
1. AWS CLI should be installed and configured with appropriate credentials.
2. Node.js and npm should be installed.

## Usage
```
./aws_cloud_dev_project.sh [-n name] -e email -a action [create | delete] -c count -s start index (integer)
```

## Command-line Arguments
- `-n <name>`: (Optional) Unique name for the project. If not provided, a random UUID will be used.
- `-e <email>`: (Required) Email address to be associated with the AWS resources.
- `-a <action>`: (Required) Action to be performed. Allowed values: `create`, `delete`.
- `-c <count>`: (Required) Number of resources to create or delete.
- `-s <start index>`: (Optional) Starting index for the resource iteration. Default value is 1.

## Steps
The script defines several steps to create or delete resources. The steps are as follows:
1. Clone GitHub repo into CodeCommit and push changes.
2. Build and create an S3 bucket for API deployment.
3. Package and deploy Lambda functions and DynamoDB resources for the API.
4. Package and deploy the Docusaurus documentation.
5. Package and deploy Cognito for authentication.
6. Package and deploy CloudFront CDN and Lambda@Edge for the documentation.

## Usage Examples
1. To create 3 sets of resources:
```
./aws_cloud_dev_project.sh -n myproject -e john@example.com -a create -c 3
```

2. To delete 2 sets of resources:
```
./aws_cloud_dev_project.sh -n myproject -e john@example.com -a delete -c 2
```

## Notes
- The `create` and `delete` functions handle the creation and deletion of resources for each iteration.
- Resources are identified using the combination of `name` and the iteration number.
- The script checks for required parameters and valid values before proceeding with the action.
- If the `start index` is not provided, the script will start from the first iteration (index 1).
- During deletion, make sure to pass the same `name` value on the resources you want to delete.
- If encountered an error, make sure you delete that (index) iteration by running `./aws_cloud_dev_project.sh -n myproject -e john@example.com -a delete -c 2 -s 2`. The iteration will start on the 2nd loop and won't delete the previous iteration. Then recreate the resources by `./aws_cloud_dev_project.sh -n myproject -e john@example.com -a create -c 10 -s 2`, means that there will be a total of 10 user iteration to be created and start from 2nd iteration up to 10.

## Disclaimer
This script should be used with caution as it performs resource creation and deletion in your AWS account. Make sure to review the script and ensure it aligns with your requirements before execution. Always test the script in a controlled environment before using it in production.


# Function Documentation: Delete Lambda Functions

## Description
This bash script `lambda-edge-delete.sh` is used to delete Lambda functions in AWS. The script takes a unique name as a command-line argument and deletes all Lambda functions that match the provided name. The AWS CLI is used to interact with the AWS Lambda service.

## Prerequisites
1. AWS CLI should be installed and configured with appropriate credentials.

## Usage
```
./delete_lambda_functions.sh -n <unique name>
```

## Command-line Arguments
- `-n <unique name>`: (Required) Unique name to match Lambda functions for deletion.

## Steps
1. The script reads the command-line arguments and checks for the required `unique name`.
2. It queries the AWS Lambda service to find all functions that contain the provided `unique name`.
3. For each matching Lambda function, it proceeds to delete the function using the AWS CLI.

## Usage Example
```
./delete_lambda_functions.sh -n my_function
```
This example will delete all Lambda functions with names containing "my_function".

## Notes
- The script uses `jq` to parse the AWS CLI output and filter functions based on the provided `unique name`.
- It iterates over each matching function and deletes them one by one using `aws lambda delete-function` command.
- The `name` to be passed is the name that is used in creating the resources. It will be search as a wildcard and loop through the list and delete.
- These functions won't be deleted after some time because it is being replicated by Lambda@Edge.

## Disclaimer
This script should be used with caution as it performs deletions in your AWS account. Make sure to review the script and ensure it aligns with your requirements before execution. Always test the script in a controlled environment before using it in production.