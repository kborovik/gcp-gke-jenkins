/*

GKE Proxy Host

*/

resource "google_compute_instance" "gke_proxy1" {
  project                   = var.google_project_id
  name                      = "gke-proxy1"
  machine_type              = "e2-small"
  desired_status            = "RUNNING"
  deletion_protection       = false
  can_ip_forward            = false
  allow_stopping_for_update = true
  zone                      = "${var.google_region}-b"

  tags = [
    var.google_project_id,
  ]

  metadata = {
    "user-data" = templatefile("cloud-init/gke-proxy.sh",
      {
        google_project_id = var.google_project_id
      }
    )
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2004-lts"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gke1.self_link
  }

  service_account {
    scopes = ["cloud-platform", "storage-rw"]
  }

  shielded_instance_config {
    enable_secure_boot = true
  }
}
