export AWS_PROFILE=icesat
export AWS_REGION=us-east-1

export LAMBDA_FUNCTION_NAME="pdal-pipeline2"
export LAMBDA_METHOD_NAME="pdal_pipeline"
export LAMBDA_EVENT_QUEUE="pipeline2"
export LAMBDA_EXECUTION_ROLE="icesat_lambda_execution"
export OUTPUT_BUCKET="pdalpipe"


create-queues:
	python create-queues.py ${LAMBDA_EVENT_QUEUE}

create-lambda-role:
	./create-lambda-role.sh ${LAMBDA_EXECUTION_ROLE}

create-lambda:
	echo "hello"
	./create-lambda-function.sh ${LAMBDA_FUNCTION_NAME} ${LAMBDA_METHOD_NAME} ${LAMBDA_EVENT_QUEUE} ${LAMBDA_EXECUTION_ROLE}

create-buckets:
	./create-s3-buckets.sh ${OUTPUT_BUCKET} ${LAMBDA_FUNCTION_NAME}

update-lambda:
	./update-lambda-function.sh ${LAMBDA_FUNCTION_NAME} ${LAMBDA_METHOD_NAME} ${LAMBDA_EVENT_QUEUE}



