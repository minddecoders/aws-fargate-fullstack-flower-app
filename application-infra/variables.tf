# ============================================================================
# VARIABLES: FULL-STACK MICROSERVICES & PERSISTENCE
# ============================================================================

variable "aws_region" {
  type        = string
  description = "The AWS target deployment region"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  type        = string
  description = "Base CIDR range for the full-stack application VPC"
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR range for the public application tier"
  default     = "10.30.1.0/24"
}

variable "public_subnet_b_cidr" {
  type        = string
  description = "CIDR range for the second public subnet"
  default     = "10.30.3.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR range for the first private database subnet"
  default     = "10.30.2.0/24"
}

variable "private_subnet_b_cidr" {
  type        = string
  description = "CIDR range for the second private database subnet"
  default     = "10.30.4.0/24"
}

variable "public_instance_ami" {
  type        = string
  description = "AMI ID for the public Nginx web server"
  default     = "ami-04df7d76c1b804451"
}

variable "private_instance_ami" {
  type        = string
  description = "AMI ID for the private backend server"
  default     = "ami-04df7d76c1b804451"
}

variable "instance_type" {
  type        = string
  description = "EC2 computing tier instance type"
  default     = "t3.micro"
}

# ============================================================================
# CONTAINER CONFIGURATION
# ============================================================================

variable "container_port" {
  type        = number
  description = "Port exposed by the application container"
  default     = 80
}

variable "container_image" {
  type        = string
  description = "Docker image used by the ECS task"
  default     = null
  nullable    = true
}

# ============================================================================
# 🔐 STATEFUL DATA TIER CREDENTIAL GATES
# ============================================================================

variable "db_password" {
  type        = string
  description = "Master administrative password for the isolated RDS MySQL cluster"
  sensitive   = true
  nullable    = false
}