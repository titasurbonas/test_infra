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
	security_groups = [aws_security_group.ssh-sg.id]

	tags = {
		Name = "primary_network_interface"
	}
}
resource "aws_instance" "public_instance" {
	#name                 = "ec2_public"
	ami                  = "ami-0ce1e3f77cd41957e" #Amazon linux # ami-032e5b6af8a711f30" #redhat "
	instance_type        = "t2.micro"
	key_name             = "ecs_exercise_lu"
	iam_instance_profile = aws_iam_instance_profile.ec2_role.name
	#subnet_id 			 = module.vpc.public_subnet_id[0]
	#iam_instance_profile = aws_iam_instance_profile.ecs.id
	#vpc_security_group_ids  = [aws_security_group.ssh-sg.id]
	network_interface {
		network_interface_id = aws_network_interface.network_interface.id
		device_index         = 0
 	}
	user_data = data.template_file.user_data.rendered
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

resource "aws_security_group" "ssh-sg" {
  	name = "ec2-sg"
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

resource "aws_s3_bucket_public_access_block" "example" {
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