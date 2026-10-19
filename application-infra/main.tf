
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

# ============================================================================
# LOCALS AND SEEDED IMAGE REFERENCES
# ============================================================================

locals {
  project_name = "aws-fargate-fullstack-app"

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

  common_tags = {
    Project     = local.project_name
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "backend_image" {
  name = "/${terraform.workspace}/backend-image-tag"
}

data "aws_ssm_parameter" "frontend_image" {
  name = "/${terraform.workspace}/frontend-image-tag"
}

# ============================================================================
# VPC AND NETWORKING
# ============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-igw"
  })
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-public-a"
    Tier = "public"
  })
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-public-b"
    Tier = "public"
  })
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-private-a"
    Tier = "private"
  })
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-private-b"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-public-rt"
  })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-private-rt"
  })
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

resource "aws_security_group" "alb" {
  name        = "${local.project_name}-${terraform.workspace}-alb-sg"
  description = "Allow public HTTP traffic to the application load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the internet"
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

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-alb-sg"
  })
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.project_name}-${terraform.workspace}-ecs-sg"
  description = "Allow application traffic only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Backend API traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Frontend HTTP traffic from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-ecs-sg"
  })
}

resource "aws_security_group" "public_vm" {
  name        = "${local.project_name}-${terraform.workspace}-public-vm-sg"
  description = "SSH access to public management instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from the configured administrator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["37.111.170.134/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-public-vm-sg"
  })
}

resource "aws_security_group" "private_vm" {
  name        = "${local.project_name}-${terraform.workspace}-private-vm-sg"
  description = "Allow SSH only from the public management instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from public management instance"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_vm.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-private-vm-sg"
  })
}

resource "aws_security_group" "database" {
  name        = "${local.project_name}-${terraform.workspace}-database-sg"
  description = "Allow MySQL only from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-database-sg"
  })
}

# ============================================================================
# EC2 MANAGEMENT INSTANCES AND SSM
# ============================================================================

resource "aws_iam_role" "ec2_ssm" {
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

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${local.project_name}-${terraform.workspace}-ec2-profile"
  role = aws_iam_role.ec2_ssm.name
}

resource "aws_instance" "public_vm" {
  ami                         = var.public_instance_ami
  instance_type               = local.current_instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.public_vm.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-public-vm"
  })

  depends_on = [aws_route_table_association.public_a]
}

resource "aws_instance" "private_vm" {
  ami                    = var.private_instance_ami
  instance_type          = local.current_instance_type
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.private_vm.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  associate_public_ip_address = false

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-private-vm"
  })

  depends_on = [
    aws_route_table_association.private_a,
    aws_route_table.private
  ]
}

# ============================================================================
# RDS MYSQL AND AUTOMATIC MASTER PASSWORD
# ============================================================================

resource "aws_db_subnet_group" "main" {
  name = "${local.project_name}-${terraform.workspace}-db-subnets"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-db-subnets"
  })
}

resource "aws_db_instance" "fullstack_rds" {
  identifier = "${terraform.workspace}-fullstack-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "fullstackdb"
  username = "appadmin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  multi_az = terraform.workspace == "prod"

  backup_retention_period    = terraform.workspace == "prod" ? 7 : 1
  deletion_protection        = terraform.workspace == "prod"
  skip_final_snapshot        = terraform.workspace != "prod"
  auto_minor_version_upgrade = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${terraform.workspace}-mysql"
  })
}

# ============================================================================
# ECS TASK EXECUTION ROLE AND SECRET ACCESS
# ============================================================================

resource "aws_iam_role" "ecs_execution" {
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

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_database_secret" {
  name = "${local.project_name}-${terraform.workspace}-database-secret-access"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_db_instance.fullstack_rds.master_user_secret[0].secret_arn
    }]
  })
}

# ============================================================================
# ECS CLUSTER AND CLOUDWATCH LOG GROUPS
# ============================================================================

resource "aws_ecs_cluster" "main" {
  name = "${local.project_name}-${terraform.workspace}-cluster"

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.project_name}/${terraform.workspace}/backend"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.project_name}/${terraform.workspace}/frontend"
  retention_in_days = 7

  tags = local.common_tags
}

# ============================================================================
# BACKEND ECS TASK DEFINITION
# ============================================================================

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.project_name}-${terraform.workspace}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "backend-api-container"
      image     = data.aws_ssm_parameter.backend_image.value
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
          value = "fullstackdb"
        },
        {
          name  = "DB_USER"
          value = "appadmin"
        }
      ]

      secrets = [{
        name      = "DATABASE_PASSWORD"
        valueFrom = "${aws_db_instance.fullstack_rds.master_user_secret[0].secret_arn}:password::"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])

  tags = local.common_tags
}

# ============================================================================
# FRONTEND ECS TASK DEFINITION
# ============================================================================

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.project_name}-${terraform.workspace}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "frontend-container"
      image     = data.aws_ssm_parameter.frontend_image.value
      essential = true

      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])

  tags = local.common_tags
}

# ============================================================================
# APPLICATION LOAD BALANCER AND TARGET GROUPS
# ============================================================================

resource "aws_lb" "fullstack_alb" {
  name               = "${local.project_name}-${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = local.common_tags
}

resource "aws_lb_target_group" "backend" {
  # 🛡️ SAFE PREFIX: Prevents the 32-character AWS naming length crash
  name_prefix = "b-api-"
  port        = var.container_port # Ensure this variable evaluates to 3000!
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = var.health_check_path # Ensure this variable evaluates to "/health"!
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "frontend" {
  # 🛡️ SAFE PREFIX: Prevents the 32-character AWS naming length crash
  name_prefix = "f-web-"
  # 🔄 FIXED PORT: Synchronized to route directly to your frontend's internal listening engine port
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

# ============================================================================
# APPLICATION ROUTING LISTENERS & TRAFFIC POLICIES
# ============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.fullstack_alb.arn
  port              = 80
  protocol          = "HTTP"

  # Default action handles all standard browser visual interface traffic
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = local.common_tags
}

resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  # Intercepts data routing traffic matching the specific API path pattern
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = local.common_tags
}


# ============================================================================
# ECS SERVICES
# ============================================================================

resource "aws_ecs_service" "backend" {
  name            = "${local.project_name}-${terraform.workspace}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = local.current_task_count
  launch_type     = "FARGATE"

  platform_version      = "LATEST"
  wait_for_steady_state = true

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend-api-container"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.backend_api,
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.ecs_database_secret,
    aws_route_table_association.private_a,
    aws_route_table_association.private_b
  ]

  tags = local.common_tags
}

resource "aws_ecs_service" "frontend" {
  name            = "${local.project_name}-${terraform.workspace}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = local.current_task_count
  launch_type     = "FARGATE"

  platform_version      = "LATEST"
  wait_for_steady_state = true

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend-container"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_execution,
    aws_route_table_association.private_a,
    aws_route_table_association.private_b
  ]

  tags = local.common_tags
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "application_url" {
  description = "Public URL of the full-stack application"
  value       = "http://${aws_lb.fullstack_alb.dns_name}"
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.fullstack_alb.dns_name
}

output "rds_endpoint" {
  description = "Private RDS endpoint"
  value       = aws_db_instance.fullstack_rds.address
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "workspace" {
  description = "Active Terraform workspace"
  value       = terraform.workspace
}
