provider "aws" {
	region = var.aws_region
}

module "vpc" {
	source                                 = "./modules/vpc"
	cidr_block                             = "10.206.104.192/27"
	vpc_name                               = "test_vpc_exercise"
	availability_zone                      = ["${var.aws_region}a"]
	ip_subnets_private                     = var.ip_subnets_private
	ip_subnets_public                      = var.ip_subnets_public
	enable_dhcp_options                    = true
    enable_private_subnet_internet_gateway = true
    enable_public_subnet_internet_gateway  = true
	enable_dns_hostnames				   = true
	enable_dns_support					   = true
}

resource "aws_network_interface" "network_interface" {
  	subnet_id  		= module.vpc.public_subnet_id[0]
	security_groups = [aws_security_group.public_sg.id]
	tags = {
		Name = "primary_network_interface"
	}
}

# ToDo move ec2 resources to module 
#######
# EC2 #
#######

resource "aws_instance" "public_instance" {
	#name                 = "ec2_public"
	ami                  = "ami-0ce1e3f77cd41957e" #Amazon linux # ami-032e5b6af8a711f30" #redhat "
	instance_type        = "t2.micro"
	key_name             = "ecs_exercise_lu"
	# ToDo create instance profile with permissions and SM read permissions  
	iam_instance_profile = aws_iam_instance_profile.ec2_role.name
	network_interface {
		network_interface_id = aws_network_interface.network_interface.id
		device_index         = 0
 	}
	# ToDo Create new user data file for public instance 
	user_data = data.template_file.user_data_private.rendered
    tags = {
    	Name = "ec2_public"
  	} 
}


resource "aws_eip" "elastic_ip" {
	depends_on = [module.vpc]
	vpc 	   = true
	instance   = aws_instance.public_instance.id
	tags = {
		Name = "ec2_public_eip"
	}
}

resource "aws_security_group" "public_sg" {
  	name = "public_sg"
	vpc_id      = module.vpc.vpc_id
  	description = "Allowed sh"

	ingress {
		from_port = 22
		to_port   = 22
		protocol  = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 80
		to_port   = 80
		protocol  = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags ={
		Name = "ec2-sg"
	}
}


resource "aws_instance" "private_instance" {
	#name                 = "ec2_public"
	ami                  = "ami-0ce1e3f77cd41957e" #Amazon linux # ami-032e5b6af8a711f30" #redhat "
	instance_type        = "t2.micro"
	key_name             = "ecs_exercise_lu"
	iam_instance_profile = aws_iam_instance_profile.ec2_role.name
	subnet_id 			 = module.vpc.private_subnet_id[0]
	#iam_instance_profile = aws_iam_instance_profile.ecs.id
	vpc_security_group_ids  = [aws_security_group.private_sg.id]

	user_data = data.template_file.user_data_private.rendered
    tags = {
    	Name = "ec2_private"
  	} 
}

resource "aws_security_group" "private_sg" {
  	name = "private_sg"
	vpc_id      = module.vpc.vpc_id
  	description = "Allowed sh"

	ingress {
		from_port = 22
		to_port   = 22
		protocol  = "tcp"
		cidr_blocks = var.ip_subnets_public
	}
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = var.ip_subnets_public
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags ={
		Name = "ec2-sg"
	}
}

#######
# S3  #
#######

resource "aws_s3_bucket" "s3_bucket" {
	bucket = "something-unique-ec2-access-bucket"
	acl    = "private"
	server_side_encryption_configuration {
		rule{
			apply_server_side_encryption_by_default {
				sse_algorithm = "AES256"
			}
		}
	}

	tags = {
		Name = "ec2-files"
	}
}

resource "aws_s3_bucket_public_access_block" "s3_block_public_access" {
	bucket = aws_s3_bucket.s3_bucket.id
	block_public_acls = true
	ignore_public_acls   = true
	block_public_policy = true
	restrict_public_buckets =true
}

resource "aws_s3_bucket_object" "html_file" {
	bucket = aws_s3_bucket.s3_bucket.id
	key    = "index.html"
	source = "${path.module}/s3_files/index.html"
	etag = filemd5("${path.module}/s3_files/index.html")
}

resource "aws_s3_bucket_object" "python_file" {
	bucket = aws_s3_bucket.s3_bucket.id
	key    = "download_file.py"
	source = "${path.module}/s3_files/download_file.py"
	etag = filemd5("${path.module}/s3_files/download_file.py")
}


###############
# IAM profile #
###############

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = file("${path.module}/policies/ec2_assume_role_policy.json")

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "ec2_role" {
  name = "test_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy" "policy" {
  name        = "test_policy"
  path        = "/"
  description = "My test policy"

  policy = data.template_file.ec2_profile_policy.rendered 
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.policy.arn
}


##############
# CloudWatch #
##############
resource "aws_cloudwatch_dashboard" "EC2-monitor" {
  dashboard_name = "EC2-monitor"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "${aws_instance.public_instance.id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "title": "EC2 Public CPU"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "${aws_instance.private_instance.id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "title": "EC2 Private CPU"
      }
    }
  ]
}
EOF
}