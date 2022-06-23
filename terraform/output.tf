/*

Terraform outputs

*/
output "google_project_id" {
  value = var.google_project_id
}

output "google_region" {
  value = var.google_region
}

output "gke_name" {
  value = try(google_container_cluster.gke1.name, null)
}

output "gke_proxy_name" {
  value = try(google_compute_instance.gke_proxy1.name, null)
}
