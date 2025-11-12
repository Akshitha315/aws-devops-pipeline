variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "aws-devops-pipeline"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "public_key" {
  description = "Public SSH key text (optional). If provided, an aws_key_pair will be created"
  type        = string
  default     = ""
}

variable "docker_image" {
  description = "Docker image that EC2 user_data will pull and run (replace with your image or ECR path)"
  type        = string
  default     = "yourdockerhubusername/aws-devops-demo:latest"
}
