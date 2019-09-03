#!/bin/bash


#./create-event-source-mapping.sh "pdal-info"  "download" "icesat_lambda_execution"
LAMBDA_FUNCTION_NAME="$1"
LAMBDA_EVENT_QUEUE="$2"
LAMBDA_EXECUTION_ROLE="$3"

PDAL_LAMBDA_LAYER_ARN="arn:aws:lambda:us-east-1:163178234892:layer:pdal:14"


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
