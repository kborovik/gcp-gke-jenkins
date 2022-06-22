output "google_project_id" {
  value = var.google_project_id
}

output "google_region" {
  value = var.google_region
}

output "gitlab_name" {
  value = try(google_compute_instance.gitlab1.name, null)
}

output "gke_name" {
  value = try(google_container_cluster.gke1.name, null)
}
