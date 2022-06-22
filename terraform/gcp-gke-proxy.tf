/*

GKE Proxy Host

*/
resource "google_compute_address" "internal_ip_gke_proxy" {
  count        = var.enable_gke_proxy == true ? 1 : 0
  name         = local.gke_proxy_dns_records[0].name
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.instances.self_link
  address      = local.gke_proxy_dns_records[0].address
}

resource "google_dns_record_set" "dns_a_record_gke_proxy" {
  count        = var.enable_gke_proxy == true ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private.name
  name         = "${local.gke_proxy_dns_records[0].name}.${google_dns_managed_zone.private.dns_name}"
  rrdatas = [
    local.gke_proxy_dns_records[0].address,
  ]
  type = "A"
  ttl  = 300
}

resource "google_compute_instance" "instance_gke_proxy" {
  count                     = var.enable_gke_proxy == true ? 1 : 0
  name                      = local.gke_proxy_dns_records[0].name
  machine_type              = var.instance_machine_type
  desired_status            = "RUNNING"
  deletion_protection       = false
  can_ip_forward            = false
  allow_stopping_for_update = true
  zone                      = "${var.region}-a"

  tags = [
    var.project_id,
  ]

  labels = {
    "os_patch"       = "yes"
    "daily_shutdown" = "yes"
    "vault_gce_role" = "gce-test-label"
  }

  metadata = {
    "ssh-keys"     = join("\n", [for key in var.ssh_keys : "${key.user}:${key.pubkey}"])
    "vmdnssetting" = "ZonalPreferred"
    "user-data" = templatefile("cloud-init/gke-proxy.sh",
      {
        root_ca_crt = google_privateca_certificate_authority.main[0].access_urls[0].ca_certificate_access_url
      }
    )
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2004-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.instances.self_link
    network_ip = google_compute_address.internal_ip_gke_proxy[count.index].address
  }

  service_account {
    scopes = ["cloud-platform"]
    email  = google_service_account.vault_client.email
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  resource_policies = [
    google_compute_resource_policy.instance_start_stop.self_link
  ]

  depends_on = [
    google_project_iam_binding.instance_schedule,
    google_compute_address.internal_ip_gke_proxy,
  ]
}
