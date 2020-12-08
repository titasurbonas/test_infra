import boto3
import sys
from botocore.exceptions import ClientError

BUCKET_NAME = sys.argv[1]
KEY = 'index.html' 

s3 = boto3.resource('s3')

try:
    s3.Bucket(BUCKET_NAME).download_file(KEY, '/home/ec2-user/site-content/index.html')
except ClientError as e:
    if e.response['Error']['Code'] == "404":
        print("The object does not exist.")
    else:
        raise