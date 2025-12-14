# Output public IP
output "public_ip" {
  value = aws_instance.go_server.public_ip
}