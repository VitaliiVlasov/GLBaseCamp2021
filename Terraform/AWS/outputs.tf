output "elb_instances" {
  value = aws_elb.bar.instances
  description = "Instances added to Load Balancer"
}

output "elb_public_dns_name" {
  value = aws_elb.bar.dns_name
  description = "DNS name of Amazon Elastic Load Balancer"
}
