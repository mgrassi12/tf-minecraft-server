output "instance_ip_addr" {
  value = aws_spot_instance_request.minecraft_server_spot_instance.public_ip
}