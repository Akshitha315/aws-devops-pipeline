# random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  name_prefix = "${var.project_name}-${random_id.suffix.hex}"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "${local.name_prefix}-vpc" }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "${local.name_prefix}-public-subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${local.name_prefix}-igw" }
}

# Route table + route to internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group allowing HTTP and SSH
resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-sg" }
}

# Optionally create key pair if public_key is provided
resource "aws_key_pair" "deployer" {
  count      = var.public_key != "" ? 1 : 0
  key_name   = "${local.name_prefix}-key"
  public_key = var.public_key
}

# Data source for Ubuntu AMI (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# EC2 instance (simple demo)
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = length(aws_key_pair.deployer) > 0 ? aws_key_pair.deployer[0].key_name : null
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker
              # Pull demo image (replace with your image or ECR)
              docker pull ${var.docker_image} || true
              # Run the container and map to port 80
              docker run -d -p 80:3000 --restart unless-stopped ${var.docker_image}
              EOF

  tags = { Name = "${local.name_prefix}-web" }
}

# S3 bucket for artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name_prefix}-artifacts"
  acl    = "private"
  tags = { Name = "${local.name_prefix}-artifacts" }
}

# Outputs for convenience
output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the EC2 instance"
}

output "s3_bucket" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "S3 bucket for artifacts"
}
