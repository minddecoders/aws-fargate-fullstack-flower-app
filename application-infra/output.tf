output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The tracking ID signature of your isolated VPC network environment"
}

output "rds_endpoint_address" {
  value       = aws_db_instance.fullstack_rds.endpoint
  description = "The internal cloud network tracking address of your managed MySQL database cluster"
}

output "alb_dns_name" {
  value       = aws_lb.fullstack_alb.dns_name
  description = "DNS name of the application load balancer"
}

output "ssm_backend_image_parameter_path" {
  value       = data.aws_ssm_parameter.backend_image.name
  description = "SSM Parameter Store path for the backend Docker image"
}

output "ssm_frontend_image_parameter_path" {
  value       = data.aws_ssm_parameter.frontend_image.name
  description = "SSM Parameter Store path for the frontend Docker image"
}
output "application_url" {
  value       = "http://${aws_lb.fullstack_alb.dns_name}"
  description = "The public web address of your full-stack deployment"
}
