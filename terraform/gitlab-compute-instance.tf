/*

GitLab Runner Host

Docker authentication:
  
On local workstation:
  gcloud auth print-access-token

On GitLab Runner:
  docker login -u oauth2accesstoken --password-stdin https://gcr.io
  docker pull gcr.io/gred-ptddtalak-dev-01-1538c72e/gcp-deployment:2022-04-03
  docker pull gcr.io/gred-ptddtalak-sb-001-e4372d8c/gcp-deployment:2022-04-03

*/
resource "google_compute_instance" "gitlab1" {
  name                      = "ptd-ii-gitlab-01"
  machine_type              = "e2-medium"
  desired_status            = "RUNNING"
  deletion_protection       = false
  can_ip_forward            = false
  allow_stopping_for_update = true
  zone                      = "${var.google_region}-c"

  tags = [
    var.google_project_id,
  ]

  metadata = {
    "user-data" = templatefile("cloud-init/gitlab-runner.sh",
      {
        google_project_id = var.google_project_id
        gitlab_token      = var.gitlab_token
      }
    )
  }

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/images/cos-93-16623-171-1"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.us_west1.self_link
  }

  service_account {
    scopes = ["cloud-platform", "storage-rw"]
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
