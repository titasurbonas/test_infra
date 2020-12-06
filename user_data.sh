#!/bin/bash

#Install pakege 
sudo yum update -y
sudo yum-config-manager --save --setopt=docker-ce-stable.skip_if_unavailable=true
sudo amazon-linux-extras install docker
sudo amazon-linux-extras install python3

# create pyton venv
python3 -m venv /home/ec2-user/python-venv
source /home/ec2-user/python-venv/bin/activate
pip install pip --upgrade
pip install boto3
deactivate

# start docker
sudo service docker start
sudo usermod -a -G docker ec2-user


#start nginx
mkdir /home/ec2-user/site-content
touch /home/ec2-user/site-content/index.html
echo "<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Docker Nginx</title>
</head>
<body>
  <h2>Hello from Nginx container</h2>
</body>
</html>" >> /home/ec2-user/site-content/index.html
mkdir /home/ec2-user/scripts
aws s3 cp s3://${S3_bucket}/${file_path} /home/ec2-user/scripts
docker run -it --rm -d -p 80:80 --name web -v /home/ec2-user/site-content:/usr/share/nginx/html nginx
 