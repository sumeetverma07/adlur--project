output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = aws_lb.app.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_app_subnet_ids" {
  value = aws_subnet.app[*].id
}

output "private_database_subnet_ids" {
  value = aws_subnet.database[*].id
}

output "database_secret_arn" {
  value     = aws_secretsmanager_secret.database.arn
  sensitive = true
}
