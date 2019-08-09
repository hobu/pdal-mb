#!/bin/bash

echo "Updating $LAMBDA_FUNCTION_NAME in $AWS_REGION for $AWS_PROFILE"

LAMBDA_FUNCTION_NAME="$1"

#AWS_PROFILE="icesat"
#AWS_REGION="us-east-1"
echo "Updating $LAMBDA_FUNCTION_NAME in $AWS_REGION for $AWS_PROFILE"

./package-lambda-function.sh lambda_function.py lambda_function.zip package

aws lambda update-function-code \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --function-name $LAMBDA_FUNCTION_NAME \
    --publish \
    --zip-file fileb://./lambda_function.zip

