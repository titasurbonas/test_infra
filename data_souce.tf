data "aws_caller_identity" "current" {}

data "template_file" "ec2_profile_policy" {
  template = "${file("${path.module}/policies/ec2_policy.json")}"
  vars = {
    s3_arn = aws_s3_bucket.s3_bucket.arn
  }
}

data "template_file" "user_data_private" {
  template = file("${path.module}/user_data_private.sh")
    vars = {
        S3_bucket = aws_s3_bucket.s3_bucket.id
        file_name = "download_file.py"
    }
}
