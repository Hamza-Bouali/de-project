terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
      config_data = jsondecode(file("${path.module}/cred.json"))
}


# Configure the AWS Provider
provider "aws" {
  region = local.config_data.region
  access_key = local.config_data.access_key
  secret_key = local.config_data.secret_key


}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"
  

  tags = {
    Name = "tf-example"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_security_group" "server_sg" {
  name        = "server-sg"
  description = "Inbound SSH/HTTP, outbound all"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "server-sg"
  }
}


resource "aws_network_interface" "server-ni" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]
  security_groups = [aws_security_group.server_sg.id]

  tags = {
    Name = "primary_network_interface"
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] # jammy = 22.04
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "server" {
  instance_type = "t3.large"
  ami           = data.aws_ami.ubuntu.id

  network_interface {
    network_interface_id = aws_network_interface.server-ni.id
    device_index         = 0
  }
  

  cpu_options {
    core_count       = 1
    threads_per_core = 1
  }
}




# Create a VPC
resource "aws_vpc" "local_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}


resource "aws_s3_bucket" "de-etl-bucket" {
  bucket = "de-etl-bucket-${random_id.bucket_suffix.hex}"

}


resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.de-etl-bucket.id

  rule {
    id     = "DeleteAndArchive"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 3
    }
  }
}


resource "aws_s3_bucket_cors_configuration" "cors-S3" {
  bucket = aws_s3_bucket.de-etl-bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 30000
  }

}

resource "aws_s3_bucket_versioning" "S3-versioning" {
  bucket = aws_s3_bucket.de-etl-bucket.id

  versioning_configuration {
    status = "Enabled"
  }

}

resource "aws_redshift_cluster" "warehouse" {
  cluster_identifier = var.redshift_config.cluster_identifier
  database_name      = var.redshift_config.database_name
  master_username    = var.redshift_config.master_username
  node_type          = var.redshift_config.node_type
  cluster_type       = var.redshift_config.cluster_type
  vpc_security_group_ids = [aws_security_group.server_sg.id]

  manage_master_password = true


  skip_final_snapshot = true
}

