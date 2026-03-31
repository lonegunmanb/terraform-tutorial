terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider to use LocalStack endpoints
provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  # Skip AWS credential validation since we're using LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Create an EC2 instance
resource "aws_instance" "tutorial" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "TerraformTutorial"
  }
}

output "instance_id" {
  value       = aws_instance.tutorial.id
  description = "The ID of the EC2 instance"
}

output "instance_type" {
  value       = aws_instance.tutorial.instance_type
  description = "The instance type of the EC2 instance"
}
