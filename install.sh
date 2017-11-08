#!/bin/bash

set -e

BUILD_DIR=./build
SRC_DIR=./src

ZIP_FILE=service.zip

STACK_NAME=podless-service

echo "Packaging code..."

# Copy source
mkdir -p $BUILD_DIR
cp -a $SRC_DIR/* $BUILD_DIR/
pip install -r $SRC_DIR/requirements.txt -t $BUILD_DIR > /dev/null

# Create the zip
cd $BUILD_DIR
zip -9 -r ../$ZIP_FILE ./ >/dev/null
cd ..

# Create a bucket
bucket_name=${STACK_NAME}-$(pwgen -A -0 8 1)
aws s3 mb s3://$bucket_name >/dev/null

echo "Deploying application"

# Do the sam deployment
sam package --template-file template.yaml --s3-bucket $bucket_name --output-template-file template.out.yaml >/dev/null
sam deploy --template-file template.out.yaml --stack-name $STACK_NAME --capabilities CAPABILITY_IAM >/dev/null

# Clean up
aws s3 rm --recursive s3://$bucket_name >/dev/null
aws s3 rb s3://$bucket_name >/dev/null
rm $ZIP_FILE
rm -r $BUILD_DIR
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
