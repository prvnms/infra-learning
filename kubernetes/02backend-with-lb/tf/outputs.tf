// Print vm's public ip
output "control_plane_public_ip" {
    value = aws_instance.control_plane.public_ip
}

output "worker_public_ips" {
    value = aws_instance.worker[*].public_ip
}

// Print vm's private ip
output "control_plane_private_ip" {
    value = aws_instance.control_plane.private_ip
}

output "worker_private_ips" {
    value = aws_instance.worker[*].private_ip
}