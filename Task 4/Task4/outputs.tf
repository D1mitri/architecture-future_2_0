output "vm_external_ip" {
  value = yandex_compute_instance.app-vm.network_interface[0].nat_ip_address
}

output "network_id" {
  value = yandex_vpc_network.app-network.id
}

output "subnet_id" {
  value = yandex_vpc_subnet.app-subnet.id
}

output "security_group_id" {
  value = yandex_vpc_security_group.app-sg.id
}

output "data_disk_id" {
  value = yandex_compute_disk.app-data-disk.id
}

output "service_account_id" {
  description = "ID of the service account"
  value       = yandex_iam_service_account.sa.id
}
