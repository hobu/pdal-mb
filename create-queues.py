import boto3
import time
import sys
import os
import json

profile = os.environ['AWS_PROFILE']
region = os.environ['AWS_REGION']
output_bucket = sys.argv[2]

boto3.setup_default_session(region_name=region,
                            profile_name=profile)
# Create SQS client
sqs = boto3.client('sqs')

VISIBILITY_TIMEOUT = 900
queues = [sys.argv[1]]
for queue in queues:

    sys.stderr.write('Creating queue %s in region %s for profile %s\n' % (queue, region, profile))
    sys.stderr.flush()

    DLQ = '%s-dlq' % queue
    QUEUE = queue
    MAXRECEIVE = 3

    for q in (DLQ, QUEUE):
        try:
            url = sqs.get_queue_url(QueueName=q)
            sqs.delete_queue(QueueUrl=url['QueueUrl'])
        except sqs.exceptions.QueueDoesNotExist:
            pass

    time.sleep(61)

    # Create a DLQ SQS queue
    response = sqs.create_queue(
        QueueName=DLQ,
        Attributes={'VisibilityTimeout': '%d' % VISIBILITY_TIMEOUT}

    )

    DLQ_URL = response['QueueUrl']

    attributes = sqs.get_queue_attributes(QueueUrl=DLQ_URL, AttributeNames=['QueueArn'])

    dlq_arn = attributes['Attributes']['QueueArn']

    # Create a SQS queue
    redrive = {"maxReceiveCount" : MAXRECEIVE, "deadLetterTargetArn": dlq_arn}
    redrive = json.dumps(redrive)

    response = sqs.create_queue(
        QueueName=QUEUE,
        Attributes={
            "RedrivePolicy" : redrive,
            'VisibilityTimeout': '%d' % VISIBILITY_TIMEOUT
        }
    )

    QUEUE_URL = response['QueueUrl']
    response = sqs.tag_queue(
            QueueUrl = QUEUE_URL,
            Tags={
                'target': output_bucket
            }
            )


