output "master_ip_address" {
  description = "Master IP addresses"
  value       = aws_eip.master.public_ip
}

output "worker_ips" {
  description = "Worker IP addresses"
  value       = aws_instance.worker[*].public_ip
}