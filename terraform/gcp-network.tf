/*

Accessing private Google Kubernetes Engine clusters with Cloud Build private pools. 
https://cloud.google.com/architecture/accessing-private-gke-clusters-with-cloud-build-private-pools

Creating GKE private clusters with network proxies for controller access. 
https://cloud.google.com/architecture/creating-kubernetes-engine-private-clusters-with-net-proxies

*/
resource "google_compute_network" "main" {
  name                    = "main"
  project                 = var.project_id
  routing_mode            = "GLOBAL"
  mtu                     = 1460
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "instances" {
  name                     = "gcp-instances"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.name
  stack_type               = "IPV4_ONLY"
  ip_cidr_range            = local.instances_cidr
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "dataproc" {
  name                     = "dataproc"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.name
  stack_type               = "IPV4_ONLY"
  ip_cidr_range            = local.dataproc_cidr
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "gke_nodes" {
  name                     = "gke-nodes"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.name
  stack_type               = "IPV4_ONLY"
  ip_cidr_range            = local.gke_nodes_cidr
  private_ip_google_access = true

  secondary_ip_range = [
    {
      range_name    = "services-gke-01"
      ip_cidr_range = "100.65.0.0/16"
    },
    {
      range_name    = "pods-gke-01"
      ip_cidr_range = "100.64.0.0/16"
    },
  ]
}

resource "google_compute_router" "main" {
  name    = "main"
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "main"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

/*

Allow access from the Health Check and IAP endpoints
https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges

*/
resource "google_compute_firewall" "allow_iap_main" {
  name     = "allow-iap-main"
  project  = var.project_id
  network  = google_compute_network.main.self_link
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
  project  = var.project_id
  network  = google_compute_network.main.self_link
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
  project  = var.project_id
  network  = google_compute_network.main.self_link
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

/*

Allow Dataproc cluster (dataproc-01) communication

*/
resource "google_compute_firewall" "allow_dataproc_01" {
  name     = "allow-dataproc-01"
  project  = var.project_id
  network  = google_compute_network.main.self_link
  priority = 400

  source_ranges = [
    "10.128.0.0/16"
  ]

  target_tags = [
    "dataproc-01",
  ]

  allow {
    protocol = "all"
  }
}
