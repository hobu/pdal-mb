#!/bin/bash

echo "Updating $LAMBDA_FUNCTION_NAME in $AWS_REGION for $AWS_PROFILE"

LAMBDA_FUNCTION_NAME="$1"
LAMBDA_METHOD_NAME="$2"
LAMBDA_EVENT_QUEUE="$3"
LAMBDA_EXECUTION_ROLE="$4"

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


QUEUEURL=$(aws sqs get-queue-url --profile $AWS_PROFILE --queue-name $LAMBDA_EVENT_QUEUE-dlq --region $AWS_REGION)
QUEUEURL=$(echo $QUEUEURL |jq .QueueUrl -r)
echo "QueueUrl: $QUEUEURL"

ATTRIBUTES=$(aws sqs get-queue-attributes --profile $AWS_PROFILE --region $AWS_REGION --queue-url $QUEUEURL --attribute-names All)
DLQ_ARN=$(echo $ATTRIBUTES |jq .Attributes.QueueArn -r)
echo "QueueArn: $DLQ_ARN"



QUEUEURL=$(aws sqs get-queue-url --profile $AWS_PROFILE --queue-name $LAMBDA_EVENT_QUEUE --region $AWS_REGION)
QUEUEURL=$(echo $QUEUEURL |jq .QueueUrl -r)
echo "QueueUrl: $QUEUEURL"

ATTRIBUTES=$(aws sqs get-queue-attributes --profile $AWS_PROFILE --region $AWS_REGION --queue-url $QUEUEURL --attribute-names All)
QUEUEARN=$(echo $ATTRIBUTES |jq .Attributes.QueueArn -r)
echo "QueueArn: $QUEUEARN"

UUID=$(aws lambda list-event-source-mappings \
        --region $AWS_REGION \
        --profile $AWS_PROFILE | jq -r '.EventSourceMappings[] | select (.EventSourceArn == "'$QUEUEARN'")|.UUID')


echo "Event UUID: $UUID"

aws lambda update-event-source-mapping \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --function-name  $LAMBDA_FUNCTION_NAME \
    --enabled \
    --uuid  $UUID
