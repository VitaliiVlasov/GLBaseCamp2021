output "elb_public_dns_name" {
  value       = aws_lb.lb.dns_name
  description = "DNS name of Amazon Elastic Load Balancer"
}
