/*

Create jenkins SA

*/
resource "google_service_account" "jenkins" {
  project      = var.google_project_id
  account_id   = "jenkins-01"
  display_name = "jenkins-01"
}

/*

Assign roles/artifactregistry.writer & roles/storage.objectViewer roles to jenkins SA

*/
resource "google_project_iam_member" "artifactregistry_writer" {
  project = var.google_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "storage_object_viewer" {
  project = var.google_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}
