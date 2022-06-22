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
  default     = "europe-west3"
}

variable "google_network" {
  description = "GCP project network"
  type        = string
  default     = null
}

variable "google_subnet1" {
  description = "Subnetwork 1"
  type        = string
  default     = null
}

/*

GitLab Runner

*/

variable "gitlab_token" {
  description = "GitLab Runner repository registration token"
  type        = string
  default     = null
}

/*

Kubernetes (GKE)

*/
variable "gke_machine_type" {
  description = "Machine type for GKE servers"
  type        = string
  default     = "e2-medium"
}

variable "gke_master_cidr" {
  description = "GKE Master CIDR"
  type        = string
  default     = null
}

variable "gke_services_range" {
  description = "GKE Services CIDR"
  type        = string
  default     = null
}

variable "gke_pods_range" {
  description = "GKE Pods CIDR"
  type        = string
  default     = null
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
