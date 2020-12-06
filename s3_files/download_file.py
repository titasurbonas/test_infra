import boto3
from botocore.exceptions import ClientError

BUCKET_NAME = 'my-bucket' 
KEY = 'my_image_in_s3.jpg' 

s3 = boto3.resource('s3')

try:
    s3.Bucket(BUCKET_NAME).download_file(KEY, 'my_local_image.jpg')
except ClientError as e:
    if e.response['Error']['Code'] == "404":
        print("The object does not exist.")
    else:
        raise