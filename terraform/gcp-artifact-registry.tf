/*

Google Artifact Registry

*/
resource "google_artifact_registry_repository" "docker" {
  provider      = google-beta
  project       = var.google_project_id
  location      = var.google_region
  repository_id = "docker"
  description   = "docker"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "jenkins" {
  provider   = google-beta
  project    = var.google_project_id
  location   = var.google_region
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.jenkins.email}"
}
