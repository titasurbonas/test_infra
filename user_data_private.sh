#!/bin/bash

#Install pakege 
sudo yum update -y
sudo yum-config-manager --save --setopt=docker-ce-stable.skip_if_unavailable=true
sudo amazon-linux-extras install docker
sudo amazon-linux-extras install python3

# Log to cloud watch 
sudo yum install -y awslogs
sudo chkconfig awslogs on
sudo systemctl enable awslogsd.service

# create pyton venv
python3 -m venv /home/ec2-user/python-venv
source /home/ec2-user/python-venv/bin/activate
pip install pip --upgrade
pip install boto
pip install botocore
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
  <p>From user data</p>
</body>
</html>" >> /home/ec2-user/site-content/index.html
mkdir /home/ec2-user/scripts
aws s3 cp s3://${S3_bucket}/${file_name} /home/ec2-user/scripts

# create pyton venv
python3 -m venv /home/ec2-user/python-venv
source /home/ec2-user/python-venv/bin/activate
sudo chmod u+x /home/ec2-user/scripts/${file_name}
python3 /home/ec2-user/scripts/${file_name} ${S3_bucket}
deactivate

docker run -it --rm -d -p 80:80 --name web -v /home/ec2-user/site-content:/usr/share/nginx/html nginx
 