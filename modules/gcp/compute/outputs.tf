output "url" {
  description = "The IP address of the VM"
  value       = var.expose == "public" ? "http://${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}:${var.port}" : "http://${google_compute_instance.main.network_interface[0].network_ip}:${var.port}"
}

output "service_name" {
  description = "VM instance name"
  value       = google_compute_instance.main.name
}

output "zone" {
  description = "Zone where the VM is running"
  value       = google_compute_instance.main.zone
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "project" {
  description = "GCP project"
  value       = var.project_id
}
