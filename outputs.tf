output "dns_publica" {
  description = "DNS publica del servidor"
  value = "http://${aws_instance.mi_servidor.public_dns}:8080"
}

output "IPV4" {
  description = "IPV4 publica del servidor"
  value = "http://${aws_instance.mi_servidor.public_ip}:8080"
}