output "dns_publica_server_1" {
  description = "DNS publica del servidor"
  value = "http://${aws_instance.Servidor_1.public_dns}:8080"
}

output "IPV4_server_1" {
  description = "IPV4 publica del servidor"
  value = "http://${aws_instance.Servidor_1.public_ip}:8080"
}

output "dns_publica_server_2" {
  description = "DNS publica del servidor"
  value = "http://${aws_instance.Servidor_2.public_dns}:8080"
}

output "IPV4_server_2" {
  description = "IPV4 publica del servidor"
  value = "http://${aws_instance.Servidor_2.public_ip}:8080"
}