output "url" {
  description = "Service endpoint"
  value       = var.expose == "public" ? "LoadBalancer (check kubectl get svc)" : "ClusterIP: ${var.service_name}.${var.namespace}.svc.cluster.local"
}

output "service_name" {
  description = "Helm release name"
  value       = helm_release.main.name
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.main.metadata[0].name
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = var.cluster_name
}

output "revision" {
  description = "Helm revision number"
  value       = helm_release.main.version
}
