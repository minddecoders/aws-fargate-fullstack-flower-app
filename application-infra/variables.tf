variable "aws_region" {
  type        = string
  description = "The AWS Target Deployment Region"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  type        = string
  description = "Base CIDR range for the automated VPC"
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR range for the front-facing public web subnet"
  default     = "10.20.1.0/24"
}

variable "public_subnet_b_cidr" {
  type        = string
  description = "CIDR range for the second public subnet tier"
  default     = "10.20.3.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR range for the private subnet A database tier"
  default     = "10.20.2.0/24"
}

variable "private_subnet_b_cidr" {
  type        = string
  description = "CIDR range for the private subnet B database tier"
  default     = "10.20.4.0/24"
}

variable "public_instance_ami" {
  type        = string
  description = "AMI ID for the public Nginx web host"
  default     = "ami-04df7d76c1b804451" # Canonical Ubuntu Server 22.04 LTS
}

variable "private_instance_ami" {
  type        = string
  description = "AMI ID for the private backend host"
  default     = "ami-04df7d76c1b804451"
}

variable "container_image" {
  type        = string
  description = "Docker image for the backend API"
  nullable    = false
}
variable "container_port" {
  description = "Port exposed by the backend API"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Backend API health-check endpoint"
  type        = string
  default     = "/health"
}