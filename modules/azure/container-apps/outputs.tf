output "url" {
  description = "FQDN of the Container App"
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "service_name" {
  description = "Container App name"
  value       = azurerm_container_app.main.name
}

output "latest_revision" {
  description = "Latest revision name"
  value       = azurerm_container_app.main.latest_revision_name
}

output "resource_group" {
  description = "Resource group name"
  value       = var.resource_group_name
}

output "environment_id" {
  description = "Container Apps Environment ID"
  value       = local.environment_id
}
