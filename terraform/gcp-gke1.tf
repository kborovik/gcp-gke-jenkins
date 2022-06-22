/*

Google Kubernetes cluster (GKE)

*/

resource "google_container_cluster" "gke1" {
  name                     = "ptd-ii-01"
  description              = "PTD-II Microservices"
  project                  = var.google_project_id
  location                 = var.google_region
  network                  = data.google_compute_network.main.self_link
  subnetwork               = data.google_compute_subnetwork.us_west1.self_link
  remove_default_node_pool = true
  initial_node_count       = 1
  min_master_version       = "1.21"
  enable_shielded_nodes    = true
  datapath_provider        = "ADVANCED_DATAPATH"

  resource_labels = {
    app   = "ptd-ii"
    owner = "rgitsc"
  }

  node_locations = [
    "${var.google_region}-a",
    "${var.google_region}-b",
    "${var.google_region}-c",
  ]

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    services_secondary_range_name = var.gke_services_range
    cluster_secondary_range_name  = var.gke_pods_range
  }

  timeouts {
    create = "30m"
    update = "60m"
    delete = "30m"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.gke_master_cidr

    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.gke_authorized_networks
      content {
        cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
        display_name = lookup(cidr_blocks.value, "display_name", "")
      }
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "08:00"
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "gke1p1" {
  name               = "p1"
  cluster            = google_container_cluster.gke1.name
  location           = var.google_region
  initial_node_count = 1
  max_pods_per_node  = 110

  autoscaling {
    max_node_count = 5
    min_node_count = 1
  }

  node_config {
    machine_type = var.gke_machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = [
      var.google_project_id,
    ]

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
  }
}
