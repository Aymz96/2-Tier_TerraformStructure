output "instance_ip_addr" {
  value = aws_instance.db_instance.private_ip
}
