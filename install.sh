#!/bin/bash

set -e

ZIP_FILE=lambda.zip

STACK_NAME=podless-service

bucket=$1
if [ -z $bucket ]; then
    read -p "S3 bucket to store template assets (e.g. mybucket): " bucket
fi

echo "Packaging code..."

./package.sh

echo "Deploying application"

# Do the sam deployment
aws cloudformation package --template-file template.yaml --s3-bucket $bucket --output-template-file template.out.yaml >/dev/null
aws cloudformation deploy --template-file template.out.yaml --stack-name $STACK_NAME --capabilities CAPABILITY_IAM >/dev/null

# Clean up
rm $ZIP_FILE
rm template.out.yaml

# Get the bucket and upload the config
outputs=$(aws cloudformation describe-stacks --stack-name $STACK_NAME | jq '.Stacks[0].Outputs | map({key: .OutputKey, value: .OutputValue}) | from_entries')
bucket=$(echo $outputs | jq -r .BucketName)
function=$(echo $outputs | jq -r .FunctionName)

if [ -z "$(aws s3 ls s3://$bucket/config.yaml)" ]; then
    aws s3 cp config.yaml s3://$bucket
fi

echo "Invoking the podless service..."
aws lambda invoke --function-name $function --invocation-type Event /dev/null >/dev/null

echo
echo "The bucket is: $bucket"
