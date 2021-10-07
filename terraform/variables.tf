variable "region" {
  description = "Used to choose the default location for regional resources. Regional resources are spread across several zones."
  type        = string
}

variable "zone" {
  description = "Used to choose the default location for zonal resources. Zonal resources exist in a single zone."
  type        = string
}

variable "project_id" {
  description = "The project indicates the default GCP project ID"
  type        = string
  default     = "palo-alto-networks-lab"
}

variable "name" {
  description = "Name of the cluster"
  type        = string
  default     = "dev-beta"
}

variable "gke_username" {
  default     = ""
  type        = string
  description = "gke username (disable basic auth by setting null username/password)"
}

variable "gke_password" {
  default     = ""
  type        = string
  description = "gke password (disable basic auth by setting null username/password)"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

variable "node_machine_type" {
  description = "The instance to use for your node instances"
  type        = string
  default     = "n1-standard-4"
}

variable "service_account_terraform" {
  description = "https://tfsec.dev/docs/google/GCP012/"
  type        = string
  default     = "fdiaz-gke-bot@gcp-gcs-pso.iam.gserviceaccount.com"
}
