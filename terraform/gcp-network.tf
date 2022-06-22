/*

Accessing private Google Kubernetes Engine clusters with Cloud Build private pools. 
https://cloud.google.com/architecture/accessing-private-gke-clusters-with-cloud-build-private-pools

Creating GKE private clusters with network proxies for controller access. 
https://cloud.google.com/architecture/creating-kubernetes-engine-private-clusters-with-net-proxies

*/
resource "google_compute_network" "main" {
  name                    = "main"
  project                 = var.google_project_id
  routing_mode            = "GLOBAL"
  mtu                     = 1460
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke1" {
  name                     = "gke1"
  project                  = var.google_project_id
  region                   = "us-central1"
  network                  = google_compute_network.main.name
  stack_type               = "IPV4_ONLY"
  ip_cidr_range            = "10.128.0.0/21"
  private_ip_google_access = true

  secondary_ip_range = [
    {
      range_name    = "gke1-services"
      ip_cidr_range = "172.16.0.0/21"
    },
    {
      range_name    = "gke1-pods"
      ip_cidr_range = "172.16.8.0/21"
    },
  ]
}

resource "google_compute_router" "main" {
  name    = "main"
  project = var.google_project_id
  region  = var.google_region
  network = google_compute_network.main.self_link
}

resource "google_compute_router_nat" "main" {
  name                               = "main"
  router                             = google_compute_router.main.name
  project                            = var.google_project_id
  region                             = var.google_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

/*

Allow access from the Health Check and IAP endpoints
https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges

*/
resource "google_compute_firewall" "allow_iap_main" {
  name     = "allow-iap-main"
  project  = var.google_project_id
  network  = google_compute_network.main.id
  priority = 100

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    "35.235.240.0/20",
    "209.85.152.0/22",
    "209.85.204.0/22",
  ]

  allow {
    protocol = "all"
  }
}

/*

Allow SSH

*/
resource "google_compute_firewall" "allow_ssh_main" {
  name     = "allow-ssh-main"
  project  = var.google_project_id
  network  = google_compute_network.main.id
  priority = 200

  source_ranges = [
    "0.0.0.0/0"
  ]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}

/*

Allow OpenVPN

*/
resource "google_compute_firewall" "allow_openvpn_main" {
  name     = "allow-openvpn-main"
  project  = var.google_project_id
  network  = google_compute_network.main.id
  priority = 300

  source_ranges = [
    "0.0.0.0/0"
  ]

  target_tags = [
    "openvpn"
  ]

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}
