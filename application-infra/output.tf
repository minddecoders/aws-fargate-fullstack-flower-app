# ============================================================================
# PHASE 6: SECTION 3 CORE FULL-STACK TELEMETRY LOGS INGRESS STRATEGY
# ============================================================================

output "vpc_id" {
  value       = aws_vpc.fullstack_vpc.id
  description = "The authoritative cloud network isolation tracking container ID"
}

output "public_instance_id" {
  value       = aws_instance.fullstack_public_vm.id
  description = "The target computational signature instance token for the public bastion node"
}

output "private_instance_id" {
  value       = aws_instance.fullstack_private_vm.id
  description = "The target computational signature instance token for the hidden database companion server"
}

output "private_instance_internal_ip" {
  value       = aws_instance.fullstack_private_vm.private_ip
  description = "The isolated private IP mapping tracking line of your backend server node"
}

output "rds_endpoint_address" {
  value       = aws_db_instance.fullstack_rds.endpoint
  description = "The internal cloud network tracking address of your managed MySQL database cluster"
}

output "alb_dns_name" {
  value       = "placeholder-load-balancer-dns"
  description = "Temporary integration bridge placeholder reference"
}
