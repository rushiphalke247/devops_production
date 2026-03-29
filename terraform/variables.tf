# =============================================================================
# Variables
# =============================================================================

variable "aws_region" {
  default = "us-south-1"
}

variable "project_name" {
  default = "devops-platform"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  default = "devops-key"
}
