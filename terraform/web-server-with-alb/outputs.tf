output "alb_dns" {
  value = aws_lb.go_alb.dns_name
}

output "ec2_public_ips" {
  value = aws_instance.go_ec2[*].public_ip
}
