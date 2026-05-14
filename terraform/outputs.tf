output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "jenkins_url" {
  value = "http://${aws_eip.jenkins_master.public_ip}:8080"
}

output "jenkins_master_public_ip" {
  value = aws_eip.jenkins_master.public_ip
}