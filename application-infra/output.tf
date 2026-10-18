output "vpc_id" {
  value       = aws_vpc.fullstack_vpc.id
  description = "The tracking ID signature of your isolated VPC network environment"
}

output "rds_endpoint_address" {
  value       = aws_db_instance.fullstack_rds.endpoint
  description = "The internal cloud network tracking address of your managed MySQL database cluster"
}

output "alb_dns_name" {
  value       = "placeholder-load-balancer-dns"
  description = "Temporary integration bridge placeholder reference"
}
output "ssm_parameter_path" {
  value       = aws_ssm_parameter.app_image_version.name
  description = "The SSM Parameter Store path tracking the deployed container image"
}