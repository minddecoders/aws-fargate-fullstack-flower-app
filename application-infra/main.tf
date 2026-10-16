# ============================================================================
# PHASE 1: TARGET CLOUD PROVIDER PLUGINS & REMOTING BACKEND
# ============================================================================
terraform {
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

# PRIMARY CLOUD PROVIDER: IRELAND
provider "aws" {
  region = var.aws_region
}

# ============================================================================
# 🛰️ SSM: Retrieve the currently approved Docker image
# ============================================================================
data "aws_ssm_parameter" "current_approved_image" {
  name = "/current/fullstack-microservices-image"
}

locals {
  approved_image = var.container_image != null ? var.container_image : data.aws_ssm_parameter.current_approved_image.value
}

# ============================================================================
# PHASE 1.1: WORKSPACE-SPECIFIC ENVIRONMENT CONFIGURATION
# ============================================================================
locals {
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

  current_instance_type = lookup(local.instance_sizes, terraform.workspace, "t3.micro")
  current_task_count    = lookup(local.ecs_task_counts, terraform.workspace, 0)
}

# ============================================================================
# PHASE 2: FULL-STACK APPLICATION NETWORK
# ============================================================================
resource "aws_vpc" "fullstack_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "fullstack-microservices-${terraform.workspace}-vpc"
  }
}

resource "aws_internet_gateway" "fullstack_igw" {
  vpc_id = aws_vpc.fullstack_vpc.id

  tags = {
    Name = "fullstack-microservices-${terraform.workspace}-igw"
  }
}

resource "aws_route_table" "fullstack_public_rt" {
  vpc_id = aws_vpc.fullstack_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fullstack_igw.id
  }

  tags = {
    Name = "fullstack-microservices-${terraform.workspace}-public-rt"
  }
}

resource "aws_subnet" "fullstack_public_subnet" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "fullstack-microservices-${terraform.workspace}-public-subnet-1a"
  }
}

resource "aws_route_table_association" "fullstack_public_assoc" {
  subnet_id      = aws_subnet.fullstack_public_subnet.id
  route_table_id = aws_route_table.fullstack_public_rt.id
}

resource "aws_subnet" "fullstack_public_subnet_b" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "fullstack-microservices-${terraform.workspace}-public-subnet-1b"
  }
}

resource "aws_route_table_association" "fullstack_public_b_assoc" {
  subnet_id      = aws_subnet.fullstack_public_subnet_b.id
  route_table_id = aws_route_table.fullstack_public_rt.id
}

resource "aws_security_group" "fullstack_web_sg" {
  name        = "fullstack-microservices-${terraform.workspace}-web-sg"
  vpc_id      = aws_vpc.fullstack_vpc.id
  description = "Web ingress security group for the full-stack application"

  ingress {
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
    Name = "fullstack-microservices-${terraform.workspace}-web-sg"
  }
}

# ============================================================================
# PHASE 3: IAM IDENTITY MANAGEMENT
# ============================================================================
resource "aws_iam_role" "fullstack_ssm_role" {
  name = "EC2-SSM-fullstack-${terraform.workspace}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fullstack_ssm_attach" {
  role       = aws_iam_role.fullstack_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "fullstack_ssm_profile" {
  name = "EC2-SSM-fullstack-${terraform.workspace}-profile"
  role = aws_iam_role.fullstack_ssm_role.name
}

# ============================================================================
# PHASE 4: EC2 COMPUTE
# ============================================================================
resource "aws_instance" "fullstack_public_vm" {
  ami                         = var.public_instance_ami
  instance_type               = local.current_instance_type
  subnet_id                   = aws_subnet.fullstack_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.fullstack_web_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.fullstack_ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF

  tags = {
    Name      = "fullstack-microservices-${terraform.workspace}-public-vm"
    ManagedBy = "Terraform-IaC"
  }
}

# ============================================================================
# PHASE 5: PRIVATE DATABASE NETWORK
# ============================================================================
resource "aws_subnet" "fullstack_private_subnet" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "fullstack-microservices-${terraform.workspace}-private-1a"
  }
}

resource "aws_subnet" "fullstack_private_subnet_b" {
  vpc_id            = aws_vpc.fullstack_vpc.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "fullstack-microservices-${terraform.workspace}-private-1b"
  }
}

resource "aws_route_table" "fullstack_private_rt" {
  vpc_id = aws_vpc.fullstack_vpc.id

  tags = {
    Name        = "fullstack-microservices-${terraform.workspace}-private-rt"
    Environment = terraform.workspace
  }
}

resource "aws_route_table_association" "fullstack_private_assoc" {
  subnet_id      = aws_subnet.fullstack_private_subnet.id
  route_table_id = aws_route_table.fullstack_private_rt.id
}

resource "aws_route_table_association" "fullstack_private_b_assoc" {
  subnet_id      = aws_subnet.fullstack_private_subnet_b.id
  route_table_id = aws_route_table.fullstack_private_rt.id
}

resource "aws_db_subnet_group" "fullstack_db_subnet_group" {
  name        = "fullstack-microservices-${terraform.workspace}-db-subnet-group"
  description = "Private subnet group for the full-stack RDS database"

  subnet_ids = [
    aws_subnet.fullstack_private_subnet.id,
    aws_subnet.fullstack_private_subnet_b.id
  ]

  tags = {
    Name        = "fullstack-microservices-${terraform.workspace}-db-subnet-group"
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

# ============================================================================
# PHASE 5.1: PRIVATE MYSQL DATABASE SECURITY
# ============================================================================
resource "aws_security_group" "fullstack_private_db_sg" {
  name        = "fullstack-microservices-${terraform.workspace}-private-db-sg"
  description = "Allow MySQL access from the full-stack application security group"
  vpc_id      = aws_vpc.fullstack_vpc.id

  ingress {
    description     = "MySQL access from the application security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.fullstack_web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "fullstack-microservices-${terraform.workspace}-private-db-sg"
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

# ============================================================================
# PHASE 5.2: AMAZON RDS MYSQL DATABASE
# ============================================================================
resource "aws_db_instance" "fullstack_rds" {
  identifier            = "fullstack-microservices-${terraform.workspace}-db"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"

  db_name  = "sidrabackenddb"
  username = "sidradbadmin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.fullstack_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.fullstack_private_db_sg.id]
  publicly_accessible    = false

  skip_final_snapshot = true

  tags = {
    Name        = "fullstack-microservices-${terraform.workspace}-db"
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

# ============================================================================
# PHASE 5.3: RDS DATABASE OUTPUT
# ============================================================================
resource "aws_instance" "fullstack_private_vm" {
  ami                    = var.private_instance_ami
  instance_type          = local.current_instance_type
  subnet_id              = aws_subnet.fullstack_private_subnet.id
  vpc_security_group_ids = [aws_security_group.fullstack_private_db_sg.id] # 👈 Fixed argument name here!
  iam_instance_profile   = aws_iam_instance_profile.fullstack_ssm_profile.name

  tags = {
    Name      = "fullstack-microservices-${terraform.workspace}-private-vm"
    ManagedBy = "Terraform-IaC"
  }
}

# ============================================================================
# PHASE 6: ECS FARGATE
# ============================================================================
resource "aws_cloudwatch_log_group" "fullstack_ecs_log_group" {
  name              = "/ecs/fullstack-microservices-${terraform.workspace}-logs"
  retention_in_days = 7

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_ecs_cluster" "fullstack_cluster" {
  name = "fullstack-microservices-${terraform.workspace}-cluster"

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_iam_role" "fullstack_ecs_task_execution_role" {
  name = "fullstack-microservices-ecs-execution-${terraform.workspace}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_iam_role_policy_attachment" "fullstack_ecs_task_execution" {
  role       = aws_iam_role.fullstack_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ============================================================================
# PHASE 6.2: ENTERPRISE SECRETS ACCESS • KMS & VAULT INLINE POLICY ATTACHMENT
# ============================================================================
resource "aws_iam_role_policy" "ecs_secrets_kms_policy" {
  name = "sidra-${terraform.workspace}-ecs-secrets-kms-access"
  role = aws_iam_role.fullstack_ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:eu-west-1:951614974272:secret:sidra-fullstack-microservices-db-secrets-E5p0GF"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:kms:eu-west-1:951614974272:key/d1cfcda9-52a5-45ca-b083-1323d2e9cf2a"
        ]
      }
    ]
  })
}

# ECS TASK DEFINITION
resource "aws_ecs_task_definition" "fullstack_task" {
  family                   = "fullstack-microservices-${terraform.workspace}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fullstack_ecs_task_execution_role.arn

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

      secrets = [
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:eu-west-1:951614974272:secret:sidra-fullstack-microservices-db-secrets-E5p0GF:password::"
        }
      ]

      environment = [
        { name = "DB_HOST", value = aws_db_instance.fullstack_rds.address },
        { name = "DB_NAME", value = "sidrabackenddb" },
        { name = "DB_USER", value = "sidradbadmin" }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.fullstack_ecs_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

# ECS SERVICE
resource "aws_ecs_service" "fullstack_service" {
  name            = "fullstack-microservices-${terraform.workspace}-service"
  cluster         = aws_ecs_cluster.fullstack_cluster.id
  task_definition = aws_ecs_task_definition.fullstack_task.arn
  desired_count   = local.current_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.fullstack_public_subnet.id,
      aws_subnet.fullstack_public_subnet_b.id
    ]

    security_groups  = [aws_security_group.fullstack_web_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fullstack_ecs_tg.arn
    container_name   = "backend-api-container"
    container_port   = var.container_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.fullstack_ecs_task_execution,
    aws_lb_listener.fullstack_http_listener
  ]

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

# ============================================================================
# PHASE 7: APPLICATION LOAD BALANCER
# ============================================================================
resource "aws_lb" "fullstack_alb" {
  name               = "fullstack-${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fullstack_web_sg.id]

  subnets = [
    aws_subnet.fullstack_public_subnet.id,
    aws_subnet.fullstack_public_subnet_b.id
  ]

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_lb_target_group" "fullstack_ecs_tg" {
  name        = "fullstack-${terraform.workspace}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.fullstack_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_lb_listener" "fullstack_http_listener" {
  load_balancer_arn = aws_lb.fullstack_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fullstack_ecs_tg.arn
  }
}