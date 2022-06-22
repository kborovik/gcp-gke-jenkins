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

data "google_compute_network" "main" {
  name = var.google_network
}

data "google_compute_subnetwork" "us_west1" {
  name   = var.google_subnet1
  region = var.google_region
}

data "google_compute_image" "cos_93_lts" {
  family  = "cos-93-lts"
  project = "cos-cloud"
}
