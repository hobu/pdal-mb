#!/bin/bash

# will create output and output-pipeline buckets hooked up
# to given lambda execution

#./create-s3-buckets.sh "pipeline"
BUCKET_NAME="$1"
LAMBDA_FUNCTION_NAME="$2"

OUTPUT_BUCKET="$BUCKET_NAME"
ACTION_BUCKET="$BUCKET_NAME-$LAMBDA_FUNCTION_NAME"

echo "Creating buckets $ACTION_BUCKET and $OUTPUT_BUCKET and attaching them to $LAMBDA_FUNCTION_NAME in $AWS_REGION for $AWS_PROFILE"

aws s3 rb s3://"$ACTION_BUCKET" --force
aws s3 rb s3://"$OUTPUT_BUCKET" --force

aws s3 mb s3://"$ACTION_BUCKET"
aws s3 mb s3://"$OUTPUT_BUCKET"

ACCOUNTID=$(aws sts \
    --region $AWS_REGION \
    get-caller-identity| jq '.Account' -r)
echo "ACCOUNTID: " $ACCOUNTID


# https://aws.amazon.com/blogs/compute/easy-authorization-of-aws-lambda-functions/

S3ARN="arn:aws:s3:::$ACTION_BUCKET"


aws lambda remove-permission \
    --function-name $LAMBDA_FUNCTION_NAME \
    --statement-id "invoke-lambda-for-$ACTION_BUCKET" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"

aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION_NAME \
    --principal s3.amazonaws.com \
    --statement-id "invoke-lambda-for-$ACTION_BUCKET" \
    --action "lambda:InvokeFunction" \
    --source-arn "$S3ARN" \
    --source-account "$ACCOUNTID" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"

notification='{
    "LambdaFunctionConfigurations": [
        {
            "Filter": {
                "Key": {
                    "FilterRules": [
                        {
                            "Name": "Suffix",
                            "Value": ".json"
                        }
                    ]
                }
            },
            "LambdaFunctionArn": "arn:aws:lambda:'$AWS_REGION':'$ACCOUNTID':function:'$LAMBDA_FUNCTION_NAME'",
            "Id": "PipelinePushEvent",
            "Events": [
                "s3:ObjectCreated:*"
            ]
        }
    ]
}'

echo $notification > notification.json

aws s3api put-bucket-notification-configuration \
        --bucket $ACTION_BUCKET \
        --notification-configuration file://notification.json

tags='{
   "TagSet": [
     {
       "Key": "target",
       "Value": "'$OUTPUT_BUCKET'"
     }
   ]
}'
echo $tags > tags.json

aws s3api put-bucket-tagging \
    --bucket "$ACTION_BUCKET"  \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --tagging file://tags.json

rm notification.json
rm tags.json

