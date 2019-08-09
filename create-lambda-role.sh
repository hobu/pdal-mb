LAMBDA_EXECUTION_ROLE="$1"
S3POLICY="arn:aws:iam::aws:policy/AmazonS3FullAccess"
SQSPOLICY="arn:aws:iam::aws:policy/AmazonSQSFullAccess"
LOGSPOLICY="lambda-put-logs"

echo "Creating $LAMBDA_EXECUTION_ROLE in $AWS_REGION for $AWS_PROFILE"


aws iam detach-role-policy \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE \
    --policy-arn $S3POLICY

aws iam detach-role-policy \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE \
    --policy-arn $SQSPOLICY

aws iam delete-role-policy \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE \
    --policy-name $LOGSPOLICY \

aws iam delete-role \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE

aws iam create-role \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE \
    --description "allow execution of lambda for magic bucket operations" \
    --assume-role-policy-document file://./policies/lambda_execution_role_policy.json

aws iam attach-role-policy \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE \
    --policy-arn $S3POLICY

aws iam attach-role-policy \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE \
    --policy-arn $SQSPOLICY

aws iam put-role-policy \
    --role-name $LAMBDA_EXECUTION_ROLE \
    --profile $AWS_PROFILE \
    --policy-name $LOGSPOLICY \
    --policy-document file://./policies/lambda_execution_log_policy.json


