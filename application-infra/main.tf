terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "sidra-terraform-state-bucket-951614974272" # Replace with your S3 bucket name if needed
    key            = "fullstack-flower-app/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# VARIABLES
# ==============================================================================

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "container_image" {
  type        = string
  description = "Docker Hub container image tag passed from CI/CD pipeline"
  default     = "minddecoders/aws-fargate-fullstack-flower-app:v1.0.0"
}

variable "db_password" {
  type        = string
  description = "Database master password injected securely via CI/CD secrets"
  sensitive   = true
}

# ==============================================================================
# WORKSPACE-SCOPED SSM PARAMETER (Zero Cold-Start & GitOps Integration)
# ==============================================================================

resource "aws_ssm_parameter" "app_image_version" {
  name        = "/${terraform.workspace}/fullstack-microservices-image"
  description = "Approved container image tag for ECS Fargate deployment in workspace ${terraform.workspace}"
  type        = "String"
  value       = var.container_image

  lifecycle {
    ignore_changes = [value] # Allows GitHub Actions to update the image tag dynamically without Terraform resetting it
  }
}

# ==============================================================================
# NETWORKING (VPC, Subnets, Internet Gateway, and Route Tables)
# ==============================================================================

resource "aws_vpc" "fullstack_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${terraform.workspace}-fullstack-vpc"
  }
}

resource "aws_internet_gateway" "fullstack_igw" {
  vpc_id = aws_vpc.fullstack_vpc.id

  tags = {
    Name = "${terraform.workspace}-fullstack-igw"
  }
}

# Public Subnets (For ALB and Public-facing ECS Tasks)
resource "aws_subnet" "fullstack_public_subnet" {
  vpc_id                  = aws_vpc.fullstack_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${terraform.workspace}-fullstack-public-subnet-a"
  }
}

resource "aws_subnet" "fullstack_public_subnet_b" {
  vpc_id                  = aws_vpc.fullstack_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${terraform.workspace}-fullstack-public-subnet-b"
  }
}

# Private Subnets (For Secure RDS MySQL Database)
resource "aws_subnet" "fullstack_private_subnet" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${terraform.workspace}-fullstack-private-subnet-a"
  }
}

resource "aws_subnet" "fullstack_private_subnet_b" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${terraform.workspace}-fullstack-private-subnet-b"
  }
}

# Public Route Table
resource "aws_route_table" "fullstack_public_rt" {
  vpc_id = aws_vpc.fullstack_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fullstack_igw.id
  }

  tags = {
    Name = "${terraform.workspace}-fullstack-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.fullstack_public_subnet.id
  route_table_id = aws_route_table.fullstack_public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.fullstack_public_subnet_b.id
  route_table_id = aws_route_table.fullstack_public_rt.id
}

# ==============================================================================
# SECURITY GROUPS
# ==============================================================================

resource "aws_security_group" "alb_sg" {
  name        = "${terraform.workspace}-alb-security-group"
  description = "Allow inbound HTTP traffic from internet to ALB"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description = "Allow HTTP from anywhere"
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

  tags = {
    Name = "${terraform.workspace}-alb-sg"
  }
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${terraform.workspace}-ecs-tasks-security-group"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description     = "Allow traffic from ALB on application port"
    from_port       = 3000 # Adjust to your Node.js application port if needed
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound traffic for Docker pulls and API calls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-ecs-tasks-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${terraform.workspace}-rds-security-group"
  description = "Allow inbound MySQL traffic exclusively from ECS tasks"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description     = "Allow MySQL access from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-rds-sg"
  }
}

# ==============================================================================
# DATABASE (RDS MySQL in Private Subnets)
# ==============================================================================

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${terraform.workspace}-rds-subnet-group"
  subnet_ids = [aws_subnet.fullstack_private_subnet.id, aws_subnet.fullstack_private_subnet_b.id]

  tags = {
    Name = "${terraform.workspace}-rds-subnet-group"
  }
}

resource "aws_db_instance" "mysql_db" {
  identifier             = "${terraform.workspace}-flower-mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "flowerapp"
  username               = "adminuser"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "${terraform.workspace}-mysql-db"
  }
}

# ==============================================================================
# APPLICATION LOAD BALANCER (ALB)
# ==============================================================================

resource "aws_lb" "app_alb" {
  name               = "${terraform.workspace}-flower-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.fullstack_public_subnet.id, aws_subnet.fullstack_public_subnet_b.id]

  tags = {
    Name = "${terraform.workspace}-flower-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${terraform.workspace}-flower-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.fullstack_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = {
    Name = "${terraform.workspace}-flower-tg"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ==============================================================================
# AWS ECS FARGATE CLUSTER & SERVICE
# ==============================================================================

resource "aws_ecs_cluster" "app_cluster" {
  name = "${terraform.workspace}-flower-cluster"

  tags = {
    Name = "${terraform.workspace}-flower-cluster"
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${terraform.workspace}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${terraform.workspace}-flower-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "flower-app-container"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.mysql_db.address },
        { name = "DB_NAME", value = aws_db_instance.mysql_db.db_name },
        { name = "DB_USER", value = aws_db_instance.mysql_db.username },
        { name = "DB_PASSWORD", value = var.db_password }
      ]
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "${terraform.workspace}-flower-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.fullstack_public_subnet.id, aws_subnet.fullstack_public_subnet_b.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "flower-app-container"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http_listener]
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "rds_endpoint_address" {
  description = "The connection endpoint for the RDS MySQL database"
  value       = aws_db_instance.mysql_db.address
}

output "vpc_id" {
  description = "The unique ID of the created VPC"
  value       = aws_vpc.fullstack_vpc.id
}

output "ssm_parameter_path" {
  description = "The SSM Parameter Store path tracking the deployed container image"
  value       = aws_ssm_parameter.app_image_version.name
}