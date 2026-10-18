
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "sidra-prod-state-vault-2026"
    key          = "fullstack-microservices-persistence/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# LOCALS
# ============================================================

locals {
  project_name = "AWS-Fargate-Fullstack-App"

  instance_sizes = {
    default = "t3.micro"
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }

  ecs_task_counts = {
    default = 0
    dev     = 1
    staging = 1
    prod    = 2
  }

  current_instance_type = lookup(
    local.instance_sizes,
    terraform.workspace,
    "t3.micro"
  )

  current_task_count = lookup(
    local.ecs_task_counts,
    terraform.workspace,
    0
  )

  approved_image = trimspace(var.container_image)
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_secretsmanager_secret" "db_secret" {
  name = "sidra-fullstack-microservices-db-secrets"
}

# This assumes the existing secret uses the AWS-managed
# Secrets Manager encryption key.
data "aws_kms_key" "secrets_kms" {
  key_id = "alias/aws/secretsmanager"
}

# ============================================================
# VPC AND NETWORKING
# ============================================================

resource "aws_vpc" "fullstack_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${local.project_name}-${terraform.workspace}-vpc"
    Project = local.project_name
  }
}

resource "aws_internet_gateway" "fullstack_igw" {
  vpc_id = aws_vpc.fullstack_vpc.id

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-igw"
  }
}

resource "aws_subnet" "fullstack_public_a" {
  vpc_id                  = aws_vpc.fullstack_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-public-a"
  }
}

resource "aws_subnet" "fullstack_public_b" {
  vpc_id                  = aws_vpc.fullstack_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-public-b"
  }
}

resource "aws_subnet" "fullstack_private_a" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-private-a"
  }
}

resource "aws_subnet" "fullstack_private_b" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-private-b"
  }
}

resource "aws_route_table" "fullstack_public_rt" {
  vpc_id = aws_vpc.fullstack_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fullstack_igw.id
  }

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-public-rt"
  }
}

resource "aws_route_table_association" "fullstack_public_assoc" {
  subnet_id      = aws_subnet.fullstack_public_a.id
  route_table_id = aws_route_table.fullstack_public_rt.id
}

resource "aws_route_table_association" "fullstack_public_b_assoc" {
  subnet_id      = aws_subnet.fullstack_public_b.id
  route_table_id = aws_route_table.fullstack_public_rt.id
}

resource "aws_eip" "fullstack_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-nat-eip"
  }
}

resource "aws_nat_gateway" "fullstack_nat" {
  allocation_id = aws_eip.fullstack_nat_eip.id
  subnet_id     = aws_subnet.fullstack_public_a.id

  depends_on = [
    aws_route_table_association.fullstack_public_assoc
  ]

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-nat"
  }
}

resource "aws_route_table" "fullstack_private_rt" {
  vpc_id = aws_vpc.fullstack_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.fullstack_nat.id
  }

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-private-rt"
  }
}

resource "aws_route_table_association" "fullstack_private_a_assoc" {
  subnet_id      = aws_subnet.fullstack_private_a.id
  route_table_id = aws_route_table.fullstack_private_rt.id
}

resource "aws_route_table_association" "fullstack_private_b_assoc" {
  subnet_id      = aws_subnet.fullstack_private_b.id
  route_table_id = aws_route_table.fullstack_private_rt.id
}

# ============================================================
# SECURITY GROUPS
# ============================================================

resource "aws_security_group" "fullstack_alb_sg" {
  name        = "${local.project_name}-${terraform.workspace}-alb-sg"
  description = "Allow HTTP traffic to the application load balancer"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-alb-sg"
  }
}

resource "aws_security_group" "fullstack_ecs_sg" {
  name        = "${local.project_name}-${terraform.workspace}-ecs-sg"
  description = "Allow application traffic only from the ALB"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description     = "Application traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.fullstack_alb_sg.id]
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-ecs-sg"
  }
}

resource "aws_security_group" "fullstack_public_vm_sg" {
  name        = "${local.project_name}-${terraform.workspace}-public-vm-sg"
  description = "Security group for public EC2 instance"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description = "SSH - restrict this to your own IP before applying"
    from_port   = 22
    to_port     = 22
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
    Name = "${local.project_name}-${terraform.workspace}-public-vm-sg"
  }
}

resource "aws_security_group" "fullstack_private_vm_sg" {
  name        = "${local.project_name}-${terraform.workspace}-private-vm-sg"
  description = "Security group for private EC2 instance"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description     = "SSH from public EC2 security group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.fullstack_public_vm_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-private-vm-sg"
  }
}

resource "aws_security_group" "fullstack_private_db_sg" {
  name        = "${local.project_name}-${terraform.workspace}-db-sg"
  description = "Allow MySQL only from ECS tasks"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description     = "MySQL from ECS backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.fullstack_ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-db-sg"
  }
}

# ============================================================
# IAM ROLE FOR EC2 SSM ACCESS
# ============================================================

resource "aws_iam_role" "fullstack_ec2_ssm_role" {
  name = "${local.project_name}-${terraform.workspace}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = local.project_name
  }
}

resource "aws_iam_role_policy_attachment" "fullstack_ec2_ssm_policy" {
  role       = aws_iam_role.fullstack_ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "fullstack_ec2_profile" {
  name = "${local.project_name}-${terraform.workspace}-ec2-profile"
  role = aws_iam_role.fullstack_ec2_ssm_role.name
}

# ============================================================
# EC2 INSTANCES
# ============================================================

resource "aws_instance" "fullstack_public_vm" {
  ami                         = var.public_instance_ami
  instance_type               = local.current_instance_type
  subnet_id                   = aws_subnet.fullstack_public_a.id
  vpc_security_group_ids      = [aws_security_group.fullstack_public_vm_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.fullstack_ec2_profile.name
  associate_public_ip_address = true

  tags = {
    Name    = "${local.project_name}-${terraform.workspace}-public-vm"
    Project = local.project_name
  }
}

resource "aws_instance" "fullstack_private_vm" {
  ami                    = var.private_instance_ami
  instance_type          = local.current_instance_type
  subnet_id              = aws_subnet.fullstack_private_a.id
  vpc_security_group_ids = [aws_security_group.fullstack_private_vm_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.fullstack_ec2_profile.name

  tags = {
    Name    = "${local.project_name}-${terraform.workspace}-private-vm"
    Project = local.project_name
  }
}

# ============================================================
# RDS MYSQL
# ============================================================

resource "aws_db_subnet_group" "fullstack_db_subnet_group" {
  name = "${local.project_name}-${terraform.workspace}-db-subnets"

  subnet_ids = [
    aws_subnet.fullstack_private_a.id,
    aws_subnet.fullstack_private_b.id
  ]

  tags = {
    Name = "${local.project_name}-${terraform.workspace}-db-subnets"
  }
}

resource "aws_db_instance" "fullstack_rds" {
  identifier = "${terraform.workspace}-fullstack-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "fullstackdb"
  username = "appadmin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.fullstack_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.fullstack_private_db_sg.id]

  publicly_accessible        = false
  multi_az                   = terraform.workspace == "prod"
  backup_retention_period    = terraform.workspace == "prod" ? 7 : 1
  deletion_protection        = terraform.workspace == "prod"
  skip_final_snapshot        = terraform.workspace != "prod"
  auto_minor_version_upgrade = true

  tags = {
    Name    = "${local.project_name}-${terraform.workspace}-mysql"
    Project = local.project_name
  }
}

# ============================================================
# ECS TASK EXECUTION ROLE
# ============================================================

resource "aws_iam_role" "fullstack_ecs_execution_role" {
  name = "${local.project_name}-${terraform.workspace}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = local.project_name
  }
}

resource "aws_iam_role_policy_attachment" "fullstack_ecs_execution_policy" {
  role       = aws_iam_role.fullstack_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "fullstack_ecs_secrets_policy" {
  name = "${local.project_name}-${terraform.workspace}-secrets-policy"
  role = aws_iam_role.fullstack_ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = data.aws_secretsmanager_secret.db_secret.arn
    }]
  })
}

# ============================================================
# ECS CLUSTER AND TASK DEFINITION
# ============================================================

resource "aws_ecs_cluster" "fullstack_cluster" {
  name = "${local.project_name}-${terraform.workspace}-cluster"

  tags = {
    Project = local.project_name
  }
}

resource "aws_cloudwatch_log_group" "fullstack_backend_logs" {
  name              = "/ecs/${local.project_name}/${terraform.workspace}/backend"
  retention_in_days = 7

  tags = {
    Project = local.project_name
  }
}

resource "aws_ecs_task_definition" "fullstack_backend_task" {
  family                   = "${local.project_name}-${terraform.workspace}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fullstack_ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend-api-container"
      image     = local.approved_image
      essential = true

      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]

      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.fullstack_rds.address
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.fullstack_rds.db_name
        },
        {
          name  = "DB_USER"
          value = aws_db_instance.fullstack_rds.username
        }
      ]

      secrets = [{
        name      = "DATABASE_PASSWORD"
        valueFrom = "${data.aws_secretsmanager_secret.db_secret.arn}:password::"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.fullstack_backend_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])

  tags = {
    Project = local.project_name
  }
}

# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

resource "aws_lb" "fullstack_alb" {
  name               = "fullstack-${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.fullstack_public_a.id,
    aws_subnet.fullstack_public_b.id
  ]

  security_groups = [aws_security_group.fullstack_alb_sg.id]

  tags = {
    Name    = "${local.project_name}-${terraform.workspace}-alb"
    Project = local.project_name
  }
}

resource "aws_lb_target_group" "fullstack_backend_tg" {
  name        = "fullstack-${terraform.workspace}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.fullstack_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Project = local.project_name
  }
}

resource "aws_lb_listener" "fullstack_http_listener" {
  load_balancer_arn = aws_lb.fullstack_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fullstack_backend_tg.arn
  }
}

# ============================================================
# ECS SERVICE
# ============================================================

resource "aws_ecs_service" "fullstack_backend_service" {
  name            = "${local.project_name}-${terraform.workspace}-backend-service"
  cluster         = aws_ecs_cluster.fullstack_cluster.id
  task_definition = aws_ecs_task_definition.fullstack_backend_task.arn
  desired_count   = local.current_task_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  wait_for_steady_state              = true

  network_configuration {
    subnets = [
      aws_subnet.fullstack_private_a.id,
      aws_subnet.fullstack_private_b.id
    ]

    security_groups  = [aws_security_group.fullstack_ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fullstack_backend_tg.arn
    container_name   = "backend-api-container"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.fullstack_http_listener,
    aws_iam_role_policy_attachment.fullstack_ecs_execution_policy,
    aws_iam_role_policy.fullstack_ecs_secrets_policy,
    aws_route_table_association.fullstack_private_a_assoc,
    aws_route_table_association.fullstack_private_b_assoc
  ]

  tags = {
    Project = local.project_name
  }
}

# ============================================================
# OUTPUTS
# ============================================================

output "application_url" {
  description = "Application Load Balancer URL"
  value       = "http://${aws_lb.fullstack_alb.dns_name}"
}

output "rds_endpoint" {
  description = "Private RDS endpoint"
  value       = aws_db_instance.fullstack_rds.address
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.fullstack_cluster.name
}

output "workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}
