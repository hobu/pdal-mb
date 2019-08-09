import boto3
import time
import os

profile = os.environ['AWS_PROFILE']
region = os.environ['AWS_REGION']

boto3.setup_default_session(region_name=region,
                            profile_name=profile)

# Create SQS client
sqs = boto3.client('sqs')

# Get the service resource
sqs = boto3.resource('sqs')

# Get the queue. This returns an SQS.Queue instance
queue = sqs.get_queue_by_name(QueueName='pipeline')

import json

message = open('mn.json','rb').read().decode('utf-8')

message = json.dumps(message)
response = queue.send_message(MessageBody=message)
