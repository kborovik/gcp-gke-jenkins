/*

General project settings

*/
variable "google_project_id" {
  description = "GCP Project Id"
  type        = string
  default     = null
}

variable "google_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

/*

Kubernetes (GKE)

*/
variable "gke_machine_type" {
  description = "Machine type for GKE servers"
  type        = string
  default     = "e2-medium"
}

variable "gke_authorized_networks" {
  description = "GKE Authorized Networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = null
      display_name = null
    }
  ]
}
