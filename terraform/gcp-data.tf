/*

Import GCP Data

*/
data "google_project" "main" {
  project_id = var.google_project_id
}

data "google_compute_zones" "available" {
  project = var.google_project_id
  region  = var.google_region
}
