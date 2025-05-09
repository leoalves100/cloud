output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = format("http://%s", aws_lb.web_server.dns_name)
}
