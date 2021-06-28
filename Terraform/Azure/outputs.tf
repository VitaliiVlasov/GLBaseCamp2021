output "elb_public_dns_name" {
  value       = azurerm_public_ip.lb.ip_address
  description = "IP address of Load Balancer"
}