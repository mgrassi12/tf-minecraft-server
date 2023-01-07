output "instance_ip_addr" {
  value = aws_instance.minecraft_server_instance.public_ip
}