# ============================================================================
# 🍏 PHASE 8: INFRASTRUCTURE CORE ROUTING & TELEMETRY OUTPUT DATA
# ============================================================================

output "vpc_id" {
  value       = aws_vpc.fullstack_vpc.id
  description = "The unique identifier of the created network VPC workspace container room"
}

output "public_web_server_url" {
  value       = "http://${aws_instance.fullstack_public_vm.public_ip}"
  description = "The live public web URL link address for the auxiliary front-facing Nginx web host"
}

output "public_instance_id" {
  value       = aws_instance.fullstack_public_vm.id
  description = "The core instance engine tracking ID identifier for the public SSM computing host node"
}

output "private_instance_internal_ip" {
  value       = aws_instance.fullstack_private_vm.private_ip
  description = "The non-routable interior private LAN address tracking space of the isolated dark database tier"
}

output "private_instance_id" {
  value       = aws_instance.fullstack_private_vm.id
  description = "The core instance engine tracking ID identifier for the backend network isolated node"
}

# ============================================================================
# 🐳 ECS CORE CLUSTER OPERATIONAL TELEMETRY
# ============================================================================

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.fullstack_cluster.name
  description = "The unique descriptive name reference string tracking your active serverless ECS orchestration container room cluster"
}

output "ecs_service_name" {
  value       = aws_ecs_service.fullstack_service.name
  description = "The cluster management tracking service handle identifier name for the application microservice tier"
}

output "ecs_task_definition" {
  value       = aws_ecs_task_definition.fullstack_task.family
  description = "The active immutable family engine group tracker mapping out settings configuration properties for the application containers"
}

# ============================================================================
# 🛡️ APPLICATION LOAD BALANCER COMPASS ROUTING RECORD
# ============================================================================

output "alb_dns_name" {
  value       = "http://${aws_lb.fullstack_alb.dns_name}"
  description = "The permanent, unchanging public domain canonical CNAME web entry link destination interface address for your live enterprise platform frontend applications storefront router room"
}