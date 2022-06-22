google_project_id = "gred-ptddtalak-sb-001-e4372d8c"
google_network    = "vpc-ptddatalak-sb-001"
google_subnet1    = "sub-prv-euw3-01"

gitlab_token = "GR1348941NUy3y58ZvvB5PKksEXbg"

gke_machine_type   = "n2-highmem-2"
gke_master_cidr    = "192.168.1.144/28"
gke_services_range = "ptd-ii-gke1-service"
gke_pods_range     = "ptd-ii-gke1-pod"
gke_authorized_networks = [
  {
    cidr_block   = "10.153.200.0/23"
    display_name = "GCP Region VPC"
  },
]
