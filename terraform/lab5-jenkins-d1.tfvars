google_project_id = "lab5-jenkins-d1"
google_region     = "us-central1"
gke_machine_type  = "n2-highmem-2"
gke_master_cidr   = "192.168.1.0/28"
gke_authorized_networks = [
  {
    cidr_block   = "10.128.0.0/21"
    display_name = "GCP VPC Main"
  },
]
