google_project_id = "lab5-jenkins-s1"
gke_machine_type  = "n2-highmem-4"
gke_authorized_networks = [
  {
    cidr_block   = "10.128.0.0/21"
    display_name = "GCP VPC Main"
  },
]
