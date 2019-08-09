#!/bin/bash


#./create-lambda-function.sh "pdal-info" "pdal_info" "download" "icesat_lambda_execution"
LAMBDA_FUNCTION_NAME="$1"
LAMBDA_METHOD_NAME="$2"
LAMBDA_EVENT_QUEUE="$3"
LAMBDA_EXECUTION_ROLE="$4"

PDAL_LAMBDA_LAYER_ARN="arn:aws:lambda:us-east-1:163178234892:layer:pdal:12"


echo "Creating $LAMBDA_FUNCTION_NAME in $AWS_REGION for $AWS_PROFILE"

ROLE=$(aws iam get-role \
    --profile $AWS_PROFILE \
    --role-name $LAMBDA_EXECUTION_ROLE )

ROLEARN=$(echo $ROLE |jq .Role.Arn -r)

QUEUEURL=$(aws sqs get-queue-url --profile $AWS_PROFILE --queue-name $LAMBDA_EVENT_QUEUE-dlq --region $AWS_REGION)
QUEUEURL=$(echo $QUEUEURL |jq .QueueUrl -r)
echo "QueueUrl: $QUEUEURL"

ATTRIBUTES=$(aws sqs get-queue-attributes --profile $AWS_PROFILE --region $AWS_REGION --queue-url $QUEUEURL --attribute-names All)
DLQ_ARN=$(echo $ATTRIBUTES |jq .Attributes.QueueArn -r)
echo "QueueArn: $DLQ_ARN"

aws lambda delete-function \
    --function-name $LAMBDA_FUNCTION_NAME \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

./package-lambda-function.sh lambda_function.py lambda_function.zip package

aws lambda create-function \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --function-name $LAMBDA_FUNCTION_NAME \
    --runtime python3.7 \
    --role $ROLEARN \
    --timeout 900 \
    --memory-size 2400 \
    --publish \
    --dead-letter-config "{ \"TargetArn\": \"$DLQ_ARN\"}" \
    --description "run '$LAMBDA_FUNCTION_NAME' on an S3 or HTTP read-only object" \
    --handler lambda_function.$LAMBDA_METHOD_NAME \
    --layers $PDAL_LAMBDA_LAYER_ARN \
    --zip-file fileb://./lambda_function.zip



QUEUEURL=$(aws sqs get-queue-url --profile $AWS_PROFILE --queue-name $LAMBDA_EVENT_QUEUE --region $AWS_REGION)
QUEUEURL=$(echo $QUEUEURL |jq .QueueUrl -r)
echo "QueueUrl: $QUEUEURL"

ATTRIBUTES=$(aws sqs get-queue-attributes --profile $AWS_PROFILE --region $AWS_REGION --queue-url $QUEUEURL --attribute-names All)
QUEUEARN=$(echo $ATTRIBUTES |jq .Attributes.QueueArn -r)
echo "QueueArn: $QUEUEARN"

UUID=$(aws lambda list-event-source-mappings \
        --region $AWS_REGION \
        --profile $AWS_PROFILE | jq -r '.EventSourceMappings[] | select (.EventSourceArn == "'$QUEUEARN'")|.UUID')

if test -z "$UUID"
then
    # nothing to delete
    echo "uuid is empty"
else
aws lambda delete-event-source-mapping \
    --uuid $UUID \
    --profile $AWS_PROFILE \
    --region $AWS_REGION

sleep 60

fi

aws lambda create-event-source-mapping \
    --event-source-arn $QUEUEARN \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --function-name $LAMBDA_FUNCTION_NAME
