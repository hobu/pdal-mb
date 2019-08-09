import os
import logging
import base64
import subprocess
import json
import boto3

# set up logger for CloudWatch
logger = logging.getLogger(__file__)
logger.setLevel(logging.DEBUG)

os.environ['GDAL_DATA'] = '/opt/share/gdal'
os.environ['PROJ_LIB'] = '/opt/share/proj'
os.environ['HOME'] = '/tmp'

def get_writer_data(json):
    for s in json:
        logger.debug(type(json))
        logger.debug(s)
        try:
            t = s['type'].split('.')[0]
            if t == 'writers':
                try:
                    return s
                except KeyError:
                    return None

        except KeyError:
            pass

def pdal_pipeline(event, context):
    """ pdal pipeline lambda handler """

    logger.debug(event)
    output_bucket = None

    record = event['Records'][0]

    pipeline = None
    if record['eventSource'] == 'aws:sqs':
        # pipeline comes through record['body'] as text
        pipeline = json.loads(json.loads(record['body']))
        logger.debug(type(pipeline))
        # TODO get target from SQS tag

    elif record['eventSource'] == 'aws:s3':
        # pipeline is the bucket/key
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        s3_client = boto3.client('s3')
        tags = s3_client.get_bucket_tagging(Bucket=bucket)['TagSet']
        for t in tags:
            if t['Key'] == 'target':
                output_bucket = t['Value']

        s3 = boto3.resource('s3')
        obj = s3.Object(bucket, key)
        pipeline = obj.get()['Body'].read().decode('utf-8')
        pipeline = json.loads(pipeline)

    writer_data = get_writer_data(pipeline)
    writer_type = writer_data['type'].split('.')[1]
    writer_filename = os.path.basename(writer_data['filename'])

    args = ['/opt/bin/pdal', 'pipeline', '--stdin', '--pipeline-serialization', 'STDOUT', '--writers.%s.filename=/tmp/%s'%(writer_type, writer_filename)]
    p = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf8')
    ret = p.communicate(input=json.dumps(pipeline))

    # If pdal pipeline returns an error code, return
    # that to the user, otherwise, set it as the body
    # and return
    if p.returncode != 0:
        error = ret[1]
        return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': error })
                }

    j = ret[0]
    pipeline = json.loads(j)

    s3 = boto3.resource('s3')
    s3.Object(output_bucket, writer_filename).put(Body=open('/tmp/%s'%writer_filename, 'rb'))

    if 'user_data' in writer_data:
        try:
            # We have S3 object tags to set
            tags = writer_data['user_data']['TagSet']
            s3_client = boto3.client('s3')
            response = s3_client.put_object_tagging(
                Bucket=output_bucket,
                Key=writer_filename,
                Tagging = {'TagSet': tags}
            )
        except KeyError:
            pass

    return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': pipeline
            }






