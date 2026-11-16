output "vm_name" {
  description = "Name of the created Compute Engine VM"
  value       = google_compute_instance.fit_manager_vm.name
}

output "public_ip" {
  description = "Public IP address of the fit_manager instance"
  value       = google_compute_instance.fit_manager_vm.network_interface[0].access_config[0].nat_ip
}

output "api_endpoint" {
  description = "Public URL to access the API"
  value       = "http://${google_compute_instance.fit_manager_vm.network_interface[0].access_config[0].nat_ip}:4000/api/v1"
}
